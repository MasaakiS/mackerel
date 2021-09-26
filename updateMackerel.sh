#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
#パラメータ
holiday_file=${SCRIPT_DIR}/holidays.yml
#APIキー(書き込み権限あり)
license=''
#ダウンタイム設定を開いた際のURL
downtimeid=''

function wh() {
grep `date -d "$1 days" '+%Y-%m-%d'` holidays.yml > /dev/null
if [ $? = 0 ];then
 echo `date -d "$1 days" '+"%A",'`
fi
}

day0=`wh '0'`
day1=`wh '1'`
day2=`wh '2'`
day3=`wh '3'`
day4=`wh '4'`
day5=`wh '5'`
day6=`wh '6'`
day7=`wh '7'`
#同じ曜日を2回入れても正常に動作することを確認済み
echo '---曜日'
holiday=${day1}${day2}${day3}${day4}${day5}${day6}${day7}
echo $holiday

#一覧取得

webres=$(bash << EOS
curl -X GET https://api.mackerelio.com/api/v0/downtimes \
    -H "X-Api-Key: ${license}" \
    -H "Content-Type: application/json"
EOS
)

if [ $? != 0 ];then
 echo '一覧取得失敗'
 exit 80
fi

echo '---オリジナルコンテンツ'
echo $webres

#該当ダウンタイムidのみを取得
echo '---ターゲット抽出'
#初期化
Body=""
Body=$webres
echo $webres|grep $downtimeid
    if [ $? = 0 ];then
        Body=$(echo ${Body}|perl -pe 's/^.*({\"id\":\"$downtimeid.*?monitorScopes.*?}).*$/$1/g')
        echo '---変換後'
        echo $Body
    else
        echo "対象のダウンタイムIDが存在しません：$downtimeid"
        exit 80
    fi

#祝祭日設定
echo '---祝祭日設定'
Body=$(echo ${Body}|perl -pe 's/\[.*?\"Sunday\"/\['$holiday'"Sunday"/g')
Body="'"$Body"'"
echo $Body

#祝祭日更新
echo '---祝祭日更新'
#どうしても直接実行できなかったため、ファイル書き出しで対応
cat - << EOS > ${SCRIPT_DIR}/updateMackerelCrulCmd.sh
curl -X PUT https://api.mackerelio.com/api/v0/downtimes/${downtimeid} \
    -H "X-Api-Key: ${license}" \
    -H "Content-Type: application/json" \
    -d ${Body}
EOS
bash ${SCRIPT_DIR}/updateMackerelCrulCmd.sh
    if [ $? -eq 0 ];then
    echo -e "\n---更新成功"
    rm -f ${SCRIPT_DIR}/updateMackerelCrulCmd.sh
    exit 0;
    else
    exit 80;
    fi


