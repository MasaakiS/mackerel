#Mackerelのダウンタイム時間を祝祭日に合わせて曜日を更新する
#注意：設定に日本語が入っていると文字化けしますが、更新は正しく行えます

#パラメータ
$holiday_file = "C:\Users\xxx\Documents\holiday.yml"
#APIキー(書き込み権限あり)
$license = ""
#ダウンタイム設定を開いた際のURL
$downtimeid = ""


#直近1週間の祝祭日の曜日を取得
#日曜日も取得してしまっているが、同じ曜日を2回入れても正常に動作することを確認済み
$day1 = Wh 1
$day2 = Wh 2
$day3 = Wh 3
$day4 = Wh 4
$day5 = Wh 5
$day6 = Wh 6
$day7 = Wh 7

#HTTPヘッダー作成
$headers = @{
'X-Api-Key' = $license
'Content-Type' = 'application/json'
}

#一覧取得

try {
$w = Invoke-WebRequest -Method Get -Uri https://api.mackerelio.com/api/v0/downtimes `
-Headers $headers
}
catch {
  echo '---一覧取得エラー'
  echo ('Error message is ' + $_)
  echo ('Error message is ' + $_.Exception.Message)
  exit 80
}

echo '---オリジナルコンテンツ'
echo $w.Content

#該当ダウンタイムidのみを取得
echo '---ターゲット抽出'
#初期化
$Body = ""
$Body = $w.Content
$is_match = ""
$is_match = $Body.Contains($downtimeid) 
    if ($is_match) {
        $Body = $Body -replace "^.*({`"id`":`"$downtimeid.*?monitorScopes.*?}).*$","`$1"
        echo $Body
    } else {
        echo "対象のダウンタイムIDが存在しません：$downtimeid"
        exit 80
    }

#祝祭日設定
echo '---祝祭日設定'
$Body = $Body -replace "\[.*?`"Sunday`"","[$day1$day2$day3$day4$day5$day6$day7`"Sunday`""
echo $Body

#祝祭日更新
try {
Invoke-WebRequest -Uri https://api.mackerelio.com/api/v0/downtimes/$downtimeid `
-Headers $headers `
-Method Put `
-Body $Body
#-Body '{"name":"connect2","start":1632240000,"duration":300,"recurrence":{"type":"weekly","interval":1,"weekdays":["Sunday"]},"monitorScopes":["3FPhWxgocxN"]}'
}
catch {
  echo '---祝祭日更新エラー'
  echo ('Error message is ' + $_)
  echo ('Error message is ' + $_.Exception.Message)
  exit 80
}


echo "---更新成功"
exit 0

#祝祭日の曜日取得
function Wh($InputString) {
$is_match = Select-String -path $holiday_file -Quiet (Get-Date).AddDays($InputString).ToString("yyyy/M/d") 
    if ($is_match) {
      Write-Output ("`"" + (Get-Date).AddDays($InputString).DayOfWeek + "`",")
    } else {
      Write-Output ""
    }
}