#!/bin/ash

echo "Provide sleep time in the form of NUMBER[SUFFIX]"
echo "   SUFFIX may be 's' for seconds (default), 'm' for minutes,"
echo "   'h' for hours, or 'd' for days."
read -p "> " delay

echo "begin allocating memory..."
for index in $(seq 1000); do
    value=$(seq -w -s '' $index $(($index + 100000)))
    eval array$index=$value
done
echo "...end allocating memory"

echo "sleeping for $delay"
sleep $delay

