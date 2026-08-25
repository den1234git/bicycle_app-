@echo off
chcp 65001 >nul
echo === bicycle_app 整理開始 ===

cd /d G:\bicycle_app

echo [1] ゴミ削除...
rmdir /s /q build 2>nul
rmdir /s /q.dart_tool 2>nul
rmdir /s /q.idea 2>nul
rmdir /s /q _c2s_full5529 2>nul
rmdir /s /q _c2s_full5529_out 2>nul
rmdir /s /q _c2s_sample100 2>nul
rmdir /s /q _c2s_sample100_out 2>nul
rmdir /s /q _deleted_backup 2>nul

echo [2] フォルダ構成確認...
dir lib

echo [3] 軽量zip作成...
powershell -Command "Compress-Archive -Path lib, pubspec.yaml -DestinationPath G:\bicycle_app_lite.zip -Force"

echo.
echo === 完了 ===
echo G:\bicycle_app_lite.zip ができた！ これなら1.3GB→数MBだよ
echo このzipをMeta AIに投げてね
pause