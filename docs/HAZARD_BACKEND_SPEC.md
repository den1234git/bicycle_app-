# 危険ポイント共有 バックエンド設計書

## 概要

ユーザー同士で危険ポイント（冠水、土砂崩れ、通行止め等）をリアルタイム共有し、
安全なルート選択を支援する。誤報対策を組み込んだ信頼スコアベースの設計。

---

## 1. データモデル

### hazard_reports（危険ポイント通報）

| カラム | 型 | 説明 |
|---|---|---|
| id | UUID | PK |
| user_id | UUID | 通報者（匿名ハッシュ可） |
| category | ENUM | 危険カテゴリ |
| lat | DOUBLE | 緯度 |
| lng | DOUBLE | 経度 |
| geom | GEOGRAPHY(Point) | PostGIS空間検索用 |
| description | TEXT | 自由記述（任意） |
| photo_url | TEXT | 写真URL（任意） |
| trust_score | FLOAT | 信頼スコア（0.0〜1.0、初期値はカテゴリ別） |
| status | ENUM | active / expired / removed |
| created_at | TIMESTAMP | 通報日時 |
| expires_at | TIMESTAMP | 自動失効日時 |
| confirm_count | INT | 確認投票数 |
| deny_count | INT | 否定投票数 |

### カテゴリ一覧

| category | 表示名 | 初期trust | 自動減衰時間 |
|---|---|---|---|
| flood | 冠水 | 0.5 | 6時間 |
| landslide | 土砂崩れ | 0.6 | 72時間 |
| road_closed | 通行止め | 0.6 | 24時間 |
| fallen_tree | 倒木 | 0.5 | 48時間 |
| construction | 工事 | 0.7 | 7日 |
| dangerous_road | 危険な道路 | 0.4 | 30日 |
| icy | 凍結 | 0.5 | 12時間 |
| poor_visibility | 視界不良 | 0.4 | 3時間 |
| other | その他 | 0.3 | 6時間 |

### hazard_votes（確認/否定 投票）

| カラム | 型 | 説明 |
|---|---|---|
| id | UUID | PK |
| report_id | UUID | FK → hazard_reports |
| user_id | UUID | 投票者 |
| vote_type | ENUM | confirm / deny / resolved |
| created_at | TIMESTAMP | 投票日時 |

UNIQUE(report_id, user_id) — 1ユーザー1投票

### user_trust（ユーザー信頼度）

| カラム | 型 | 説明 |
|---|---|---|
| user_id | UUID | PK |
| trust_level | FLOAT | 0.0〜1.0（初期0.5） |
| total_reports | INT | 累計通報数 |
| confirmed_reports | INT | 他者に確認された通報数 |
| denied_reports | INT | 否定された通報数 |
| suspended_until | TIMESTAMP | 通報停止期限（NULL=有効） |

---

## 2. 信頼スコア計算

### 通報の信頼スコア（trust_score）

```
base = カテゴリ初期値 × ユーザー信頼度
photo_bonus = 写真あり ? +0.15 : 0
confirm_bonus = confirm_count × 0.1（最大+0.3）
deny_penalty = deny_count × 0.15（最大-0.6）
time_decay = 経過時間 / 減衰時間 × 0.5

trust_score = clamp(base + photo_bonus + confirm_bonus - deny_penalty - time_decay, 0.0, 1.0)
```

### 表示ルール

| trust_score | 表示 |
|---|---|
| 0.7〜1.0 | 赤アイコン（確認済み危険） |
| 0.4〜0.7 | 黄アイコン（未確認情報） |
| 0.2〜0.4 | 薄いアイコン（信頼度低） |
| 0.0〜0.2 | 非表示 |

### ユーザー信頼度の更新

```
trust_level = 0.5 + (confirmed_reports / total_reports - 0.5) × 0.4
             （最低0.1、最高0.95）
```

- denied_reports / total_reports > 0.5 → trust_level 強制0.1
- suspended_until が未来 → 通報不可

---

## 3. 誤報対策

### 通報制限

- 同一ユーザー: 10分間に最大3件
- 同一地点（半径50m以内）: 1時間に同カテゴリ1件（重複防止）
- suspended中: 通報不可、閲覧のみ

### 自動ペナルティ

| 条件 | 処理 |
|---|---|
| deny 3票以上かつ confirm 0票 | 通報を非表示化、ユーザーにwarning |
| 直近10件中 deny率 60%以上 | 24時間通報停止 |
| 直近30件中 deny率 50%以上 | 7日間通報停止 |
| 停止3回目 | 永久停止（手動解除のみ） |

### 自動失効

- expires_at を過ぎた通報は status = expired に更新
- Cron（Cloud Functions / pg_cron）で5分ごとに処理
- resolved 投票が confirm を超えた場合も自動失効

---

## 4. API設計

### エンドポイント

```
POST   /api/v1/hazards              通報を作成
GET    /api/v1/hazards/nearby       近隣の危険ポイント取得
POST   /api/v1/hazards/:id/vote     確認/否定/解消 投票
DELETE /api/v1/hazards/:id          自分の通報を削除
POST   /api/v1/hazards/:id/photo    写真アップロード
GET    /api/v1/user/trust           自分の信頼度確認
```

### GET /api/v1/hazards/nearby

```json
// Request
{
  "lat": 35.6812,
  "lng": 139.7671,
  "radius_m": 5000,
  "min_trust": 0.2
}

// Response
{
  "hazards": [
    {
      "id": "uuid",
      "category": "flood",
      "lat": 35.6815,
      "lng": 139.7680,
      "trust_score": 0.72,
      "description": "交差点付近30cm冠水",
      "has_photo": true,
      "confirm_count": 5,
      "deny_count": 0,
      "created_at": "2026-08-27T14:30:00Z",
      "expires_at": "2026-08-27T20:30:00Z",
      "distance_m": 120
    }
  ]
}
```

### POST /api/v1/hazards

```json
// Request
{
  "category": "flood",
  "lat": 35.6815,
  "lng": 139.7680,
  "description": "交差点付近30cm冠水"
}

// Response
{
  "id": "uuid",
  "trust_score": 0.25,
  "expires_at": "2026-08-27T20:30:00Z"
}
```

---

## 5. 技術スタック

### 推奨構成: Supabase

| 層 | 技術 | 理由 |
|---|---|---|
| DB | PostgreSQL + PostGIS | 空間検索（ST_DWithin）が高速 |
| API | Supabase Edge Functions | Dart/TypeScript対応、認証組み込み |
| 認証 | Supabase Auth（匿名認証） | アカウント不要で始められる |
| ストレージ | Supabase Storage | 写真保存 |
| リアルタイム | Supabase Realtime | 新規通報のプッシュ配信 |
| Cron | pg_cron / Edge Function | 自動失効処理 |

### 代替構成: Firebase

| 層 | 技術 | 注意点 |
|---|---|---|
| DB | Firestore | GeoHash必要、空間検索は自前実装 |
| API | Cloud Functions | コールドスタート遅延あり |
| 認証 | Firebase Auth（匿名） | |
| ストレージ | Cloud Storage | |

→ **PostGISの空間検索がコア機能なのでSupabase推奨**

---

## 6. Flutter側の実装方針

### 新規ファイル

```
lib/services/hazard_service.dart      API通信
lib/models/hazard_report.dart         データモデル
lib/widgets/hazard_report_dialog.dart 通報UI
lib/widgets/hazard_map_layer.dart     地図上の表示レイヤー
```

### 地図表示

- 現在地から半径5km以内のactive通報を取得（30秒ポーリング or Realtime）
- trust_scoreに応じたアイコン色（赤/黄/薄）
- マーカータップで詳細 + 確認/否定ボタン
- ナビ中は自動で危険ポイントを音声警告

### 通報フロー

1. 地図長押し or SOSメニューから「危険ポイント通報」
2. カテゴリ選択 → 説明入力（任意） → 写真撮影（任意）
3. 送信 → 初期trust_scoreで即座に地図反映
4. 他ユーザーの確認投票でスコア上昇

---

## 7. フェーズ計画

### Phase 1: ローカル記録（バックエンド不要）

- 危険ポイントをローカルに記録・表示
- SosStoreの拡張で実装可能
- 自分の過去通報を地図上に表示

### Phase 2: 共有基盤

- Supabaseプロジェクト作成
- 匿名認証 + 通報/取得API
- 基本的な信頼スコア計算
- 近隣通報の地図表示

### Phase 3: 誤報対策強化

- 投票システム
- ユーザー信頼度
- 自動ペナルティ
- 写真添付

### Phase 4: ルート連携

- ナビルート上の危険ポイント警告
- 危険ポイントを避けるルート提案
- 音声警告「この先100m、冠水情報あり」

---

## 8. SOS緊急信号レイヤー

危険ポイント共有（信頼スコア制）とは別に、命に関わる緊急時の即時ブロードキャスト機能。
**フィルタなし・即時配信。誤報対策は事後処理。**

### 設計思想

- 緊急時に投票や信頼スコアの判定を待つ余裕はない
- 発信した瞬間に近くの全ユーザーへ通知
- 「助けが来る」が見えることが安心感に繋がる
- 向かう側も相手の位置がリアルタイムで見えることで効率的に辿り着ける

### データモデル: sos_signals

| カラム | 型 | 説明 |
|---|---|---|
| id | UUID | PK |
| user_id | UUID | 発信者（匿名ハッシュ） |
| signal_type | ENUM | 信号種別 |
| lat | DOUBLE | 最新の緯度 |
| lng | DOUBLE | 最新の経度 |
| status | ENUM | active / resolved / expired |
| message | TEXT | 簡易メッセージ（任意） |
| created_at | TIMESTAMP | 発信開始 |
| last_ping_at | TIMESTAMP | 最新位置更新 |
| resolved_at | TIMESTAMP | 解除日時 |

### signal_type

| 値 | 表示名 | 用途 |
|---|---|---|
| distress | 遭難・孤立 | 災害で孤立、山で動けない |
| accident | 事故 | 交通事故、転倒 |
| medical | 体調不良 | 熱中症、怪我 |
| threat | 身の危険 | 不審者、暴力 |

### sos_responders（救助応答）

| カラム | 型 | 説明 |
|---|---|---|
| id | UUID | PK |
| signal_id | UUID | FK → sos_signals |
| user_id | UUID | 応答者 |
| lat | DOUBLE | 応答者の最新緯度 |
| lng | DOUBLE | 応答者の最新経度 |
| status | ENUM | heading / arrived / cancelled |
| created_at | TIMESTAMP | 応答日時 |
| eta_minutes | INT | 推定到着時間 |

### リアルタイム通信フロー

```
発信者                        Supabase Realtime              近隣ユーザー
  |                                  |                           |
  |-- SOS発信（位置+種別）---------->|                           |
  |                                  |-- プッシュ通知（5km圏）-->|
  |                                  |                           |
  |-- 位置更新（30秒間隔）--------->|-- リアルタイム配信-------->|
  |                                  |                           |
  |                                  |<-- 「向かう」応答 --------|
  |<-- 応答者の位置が見える---------|-- 双方向位置共有 -------->|
  |                                  |                           |
  |-- 解除 or バッテリー切れ ------>|-- 信号終了通知 ---------->|
```

### 発信者側の画面

- SOSボタン長押し（3秒）で信号発信開始
- 全画面表示に切り替わる（赤背景）
  - 「SOS発信中...」と点滅表示
  - 現在位置を地図上に表示
  - 応答者が来たら人数と推定到着時間を表示
    - 例:「2人が向かっています（最短 約3分）」
  - 応答者の位置をリアルタイムで地図上に表示
- 30秒間隔で位置を自動更新（バックグラウンドでも動作）
- 「解除」ボタンで信号停止
- 10分間更新がなければ自動でexpired（バッテリー切れ想定）

### 応答者側の画面

- プッシュ通知:「近くでSOSが発信されています（約800m）」
- 通知タップでアプリ起動 → 発信者の位置が地図上に表示
- 「向かう」ボタンを押すと：
  - 自分の位置が発信者にリアルタイム共有される
  - 発信者までのナビが自動開始
  - 発信者側に「○○さんが向かっています」と表示
- 「キャンセル」で応答取り消し

### 誤報対策（事後処理）

| 条件 | 処理 |
|---|---|
| 発信後10秒以内に自分で解除 | ノーカウント（誤タップ救済） |
| 30日間で誤報3回（応答者からの報告） | SOS機能を30日間停止 |
| 誤報5回累計 | SOS機能永久停止（手動解除のみ） |

※ 誤報の判定: 応答者が到着後に「誤報」を報告 → 複数の応答者が報告した場合に誤報確定

### 安全設計

- 発信者の個人情報は一切表示しない（位置と信号種別のみ）
- 応答者も匿名（地図上のアイコンのみ）
- 信号終了後、位置データは24時間で自動削除
- resolved/expired後はお互いの位置が見えなくなる
- 悪意ある追跡防止: 同じ相手のSOSに1日1回しか応答できない

### Supabase Realtime実装

```sql
-- 信号チャンネル: sos:{signal_id}
-- 発信者: 30秒ごとにbroadcast（lat, lng, status）
-- 応答者: 位置更新をbroadcast
-- 近隣検索: PostGIS ST_DWithin(geom, Point(lng,lat), 5000)
```

```dart
// Flutter側: Supabase Realtimeチャンネル購読
final channel = supabase.channel('sos:$signalId');
channel.onBroadcast(event: 'location', callback: (payload) {
  // 相手の位置を地図上に更新
});
channel.onBroadcast(event: 'responder_joined', callback: (payload) {
  // 「○人が向かっています」を更新
});
```

### フェーズ（Phase 2と同時に実装可能）

1. **Phase 2a**: SOS発信 + 近隣通知（Supabase Realtime + Push）
2. **Phase 2b**: 双方向位置共有（「向かう」機能）
3. **Phase 2c**: バックグラウンド位置更新（flutter_foreground_task連携）

---

## 9. プライバシー

- ユーザーIDは端末生成UUIDのハッシュ（アカウント不要）
- 通報位置は記録するが、ユーザーの現在位置は送信しない
- 写真のEXIF情報はサーバー側で自動削除
- 通報者IDは他ユーザーに非公開
- 失効した通報データは30日後に完全削除
