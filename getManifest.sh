#!/bin/bash

urlPath=$1
outPath=$2
if [ -z "$outPath" ];then
    outPath=""
fi

function getHash()
{
    if [ ! -d "temp" ];then
        mkdir temp
    fi
    wget $1 -q -O temp/temp
    hash=$(openssl dgst -sha256 -binary temp/temp | openssl base64 -A)
    echo $hash
}

function cleanTemp()
{
    rm -rf temp
}

function writeTxt()
{
    echo -e "$1" >> ${outPath}freecdn-manifest.txt
}

function cleanTxt()
{
    rm -rf ${outPath}freecdn-manifest.txt
}

function testCDN()
{
    sourceHash=$1
    source=$2
    target=$3
    #fastly jsdelivr
    if [ "$target" == "fastly" ];then
        host="$target.jsdelivr.net"
        #如果是cdn.jsdelivr.net
        target=$(echo $source | sed -r "s/https:\/\/cdn.jsdelivr.net\/npm\/([^\s]*)/https:\/\/$host\/npm\/\1/")
        #如果是cdn.jsdelivr.net（Github）
        target=$(echo $target | sed -r "s/https:\/\/cdn.jsdelivr.net\/gh\/([^\s]*)/https:\/\/$host\/gh\/\1/")
        #如果是unpkg.com
        target=$(echo $target | sed -r "s/https:\/\/unpkg.com\/([^\s]*)/https:\/\/$host\/npm\/\1/")
    fi
    #unpkg
    if [ "$target" == "unpkg" ];then
        host="unpkg.com"
        #如果是*.jsdelivr.net
        target=$(echo $source | sed -r "s/https:\/\/([^\s]*).jsdelivr.net\/npm\/([^\s]*)/https:\/\/$host\/\2/")
    fi
    #bootcdn
    if [ "$target" == "bootcdn" ];then
        host="cdn.bootcdn.net"
        #如果是*.jsdelivr.net带版本
        target=$(echo $source | sed -r "s/https:\/\/([^\s]*).jsdelivr.net\/npm\/(.*?)@(.*?)\/(.*?)/https:\/\/$host\/ajax\/libs\/\2\/\3\/\4/")
    fi
    if [ -z "$2" ];then
        source=""
    fi
    if [ "$target" != "$source" ];then
        targetHash=$(getHash $target)
        if [ "$targetHash" == "$sourceHash" ];then
            echo $target
        fi
    fi
}

function getCDN()
{
    hash=$(getHash $1)
    echo "Get：$1"
    echo "【Hash】$hash"
    cdns=("fastly" "unpkg" "bootcdn")
    urls=()
    for cdn in ${cdns[*]}
    do
        url=$(testCDN $hash $1 $cdn)
        if [ -n "$url" ];then
            echo "【CDN】【$cdn】：$url"
            urls+=($url)
        fi
    done
    if [ ${#urls[@]} -gt 0  ];then
        writeTxt "$1"
        for url in ${urls[*]}
        do
            writeTxt "\t$url"
        done
    fi
    echo ""
}

if [ -z "$urlPath" ];then
    echo "请传入链接列表文件，以便生成清单"
else
    cleanTxt
    for line in $(cat $urlPath)
    do
        if [[ $line != "#"* ]] && [ "$line" ];then
            getCDN $line
            writeTxt ""
        fi
    done
    cleanTemp
fi