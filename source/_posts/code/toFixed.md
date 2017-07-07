
---
title: toFixed四舍五入
date: 2017-07-05 11:45:56
categories:
    - code
tags:
    - javascript
    - toFixed
---

```markdown
Number.prototype.toFixed = function (length) {
        var isF = false;
        var _this = this;
        var carry = 0; //存放进位标志
        var num, multiple; //num为原浮点数放大multiple倍后的数，multiple为10的length次方
        var str = _this + ''; //将调用该方法的数字转为字符串
        var dot = str.indexOf("."); //找到小数点的位置
        var result = str;
        if (dot > 0) {
            if (str.substr(dot + length + 1, 1) >= 5) carry = 1; //找到要进行舍入的数的位置，手动判断是否大于等于5，满足条件进位标志置为1
            multiple = Math.pow(10, length); //设置浮点数要扩大的倍数
            var multipleStr = multiple.toString();
            //精确乘法--
            var baseNum = 0;
            if (str.indexOf(".") > -1) {
                baseNum += str.split(".")[1].length
            }
            if (multipleStr.indexOf(".") > -1) {
                baseNum += multipleStr.split(".")[1].length;
            }
            baseNum = Number(str.replace(".", "")) * Number(multipleStr.replace(".", "")) / Math.pow(10, baseNum);
            //精确乘法--

            num = Math.floor(baseNum) + carry; //去掉舍入位后的所有数，然后加上我们的手动进位数
            result = num / multiple + ''; //将进位后的整数再缩小为原浮点数
        }
        /*
         * 处理进位后无小数
         */
        dot = result.indexOf(".");
        if (dot < 0) {
            result += '.';
            dot = result.indexOf(".");
        }
        /*
         * 处理多次进位
         */
        var len = result.length - (dot + 1);
        if (len < length) {
            for (var i = 0; i < length - len; i++) {
                result += 0;
            }
        }
        return result;
    }
```