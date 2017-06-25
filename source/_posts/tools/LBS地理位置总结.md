
---
title: LBS地理位置搜索
date: 2017-06-26 00:00:00
reward: true
categories:
    - tools
tags:
    - LBS
    - 地理位置
---

1.数据库查询-按经纬度排序
* 经纬度的数据库字段类型为float(10,6).
* 获取用户经纬度:$latitude;$longitude
* 定义一个差值，设置经度和纬度的范围
```markdown
$i = 0.3; //差值可自定义，值越大，范围就越大
$min_latitude = $latitude - $i; //纬度最小值
$max_latitude = $latitude + $i; //纬度最大值
$min_longitude = $longitude - $i; //经度最小值
$max_longitude = $longitude + $i; //经度最大值
```
* 排序／查询
```markdown
SELECT *,SQRT(POWER($latitude - latitude, 2) + POWER($longitude  - longitude, 2)) AS d FROM table WHERE (latitude BETWEEN $min_latitude AND $max_latitude) AND (longitude BETWEEN $min_longitude AND $max_longitude) ORDER BY d ASC LIMIT 10;
```
2.计算经纬度两点之间的距离
```markdown
    private static final  double EARTH_RADIUS = 6378.137;//赤道半径(单位km)(此处单位km则算出来的距离就是km;此处单位为m，则算出来的距离就是m)
    private static double rad(double d)  
    {  
        return d * Math.PI / 180.0;  
    }
	/**
	 * 基于余弦定理求两经纬度距离
	 * @param lon1 第一点的精度
	 * @param lat1 第一点的纬度
	 * @param lon2 第二点的精度
	 * @param lat1 第二点的纬度
	 * @return 返回的距离，单位km
	 * */
	public static double getDistance(double lat1,double lon1, double lat2, double lon2) {
		double radLat1 = rad(lat1);
		double radLat2 = rad(lat2);

		double radLon1 = rad(lon1);
		double radLon2 = rad(lon2);

		if (radLat1 < 0)
			radLat1 = Math.PI / 2 + Math.abs(radLat1);// south
		if (radLat1 > 0)
			radLat1 = Math.PI / 2 - Math.abs(radLat1);// north
		if (radLon1 < 0)
			radLon1 = Math.PI * 2 - Math.abs(radLon1);// west
		if (radLat2 < 0)
			radLat2 = Math.PI / 2 + Math.abs(radLat2);// south
		if (radLat2 > 0)
			radLat2 = Math.PI / 2 - Math.abs(radLat2);// north
		if (radLon2 < 0)
			radLon2 = Math.PI * 2 - Math.abs(radLon2);// west
		double x1 = EARTH_RADIUS * Math.cos(radLon1) * Math.sin(radLat1);
		double y1 = EARTH_RADIUS * Math.sin(radLon1) * Math.sin(radLat1);
		double z1 = EARTH_RADIUS * Math.cos(radLat1);

		double x2 = EARTH_RADIUS * Math.cos(radLon2) * Math.sin(radLat2);
		double y2 = EARTH_RADIUS * Math.sin(radLon2) * Math.sin(radLat2);
		double z2 = EARTH_RADIUS * Math.cos(radLat2);

		double d = Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)+ (z1 - z2) * (z1 - z2));
		//余弦定理求夹角
		double theta = Math.acos((EARTH_RADIUS * EARTH_RADIUS + EARTH_RADIUS * EARTH_RADIUS - d * d) / (2 * EARTH_RADIUS * EARTH_RADIUS));
		double dist = theta * EARTH_RADIUS;
		return dist;
	}
```
假设有个包含经纬度的pojo对象PositionInfo,按位置信息排序PositionInfo对象列表
3.按距离排序
```markdown
/**
     * 排序
     * @param list
     * @param latitude
     * @param longitude
     * @return
     */
    private List<PositionInfo> sortPositionInfos(List<PositionInfo> list,BigDecimal latitude,BigDecimal longitude){
        if(list==null || list.isEmpty()){
            return list;
        }
        if(list.size()==1){
            PositionInfo item = list.get(0);
            BigDecimal o1Latitude = item.getLatitude();
            BigDecimal o1Longitude = item.getLongitude();
            if (o1Latitude == null || o1Longitude == null || latitude==null || longitude==null) {
                item.set("distance", "未知");
            } else {
                item.set("distance",Toolkit.getDistance(o1Latitude.doubleValue(),o1Longitude.doubleValue(),latitude.doubleValue(),longitude.doubleValue()));
            }
            return list;
        }
        list.sort((position1,position2) -> {
            if (position1 != null && position1.hasId() && position2 != null && position2.hasId()) {
                BigDecimal o1Latitude = position1.getLatitude();
                BigDecimal o2Latitude = position2.getLatitude();
                BigDecimal o1Longitude = position1.getLongitude();
                BigDecimal o2Longitude = position2.getLongitude();
                Double distance1 = 0.0;
                Double distance2 = 0.0;
                if (o1Latitude == null || o1Longitude == null || latitude==null || longitude==null) {
                    position1.set("distance", "未知");
                } else {
                    // position1 =
                    // Math.sqrt(Math.pow(o1Latitude.doubleValue()-latitude.doubleValue(),2)+Math.pow(o1Longitude.doubleValue()-longitude.doubleValue(),2));
                    distance1 = Toolkit.getDistance(o1Latitude.doubleValue(), o1Longitude.doubleValue(),latitude.doubleValue(), longitude.doubleValue());
                    position1.set("distance", distance1);
                }
                if (o2Latitude == null || o2Longitude == null || latitude==null || longitude==null) {
                    position2.set("distance", "未知");
                } else {
                    // position2 =
                    // Math.sqrt(Math.pow(o2Latitude.doubleValue()-latitude.doubleValue(),2)+Math.pow(o2Longitude.doubleValue()-longitude.doubleValue(),2));
                    distance2 = Toolkit.getDistance(o2Latitude.doubleValue(), o2Longitude.doubleValue(),latitude.doubleValue(), longitude.doubleValue());
                    position2.set("distance", distance2);
                }
                return distance1.compareTo(distance2);
            }
            return 0;
        });
        return list;
    }
```