#!/bin/bash

echo "🌐 Testing Serverless Task Manager Performance"
echo "=============================================="

S3_URL="http://serverless-task-managerfrontend.s3-website-us-east-1.amazonaws.com"

echo "📍 Testing S3 Direct Access:"
echo "URL: $S3_URL"
echo ""

echo "⏱️  Response Time Test:"
time curl -s -o /dev/null -w "HTTP Status: %{http_code}\nTotal Time: %{time_total}s\nConnect Time: %{time_connect}s\nSize Downloaded: %{size_download} bytes\n" $S3_URL

echo ""
echo "🔍 Headers Analysis:"
curl -I $S3_URL

echo ""
echo "📊 Performance Summary:"
echo "✅ S3 Website: Working"
echo "❌ HTTPS: Not available"
echo "⚠️  CDN: Not configured"
echo "📍 Region: US East 1 only"

echo ""
echo "🚀 To enable HTTPS + Global CDN:"
echo "1. Follow CLOUDFRONT_SETUP_GUIDE.md"
echo "2. Or run setup-cloudfront.sh (requires permissions)"
echo "3. Or use AWS Console manually"