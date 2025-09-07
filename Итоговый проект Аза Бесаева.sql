/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Бесаева Аза
 * Дата: 12 апреля 2025
*/

-- Пример фильтрации данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    ),
-- вычисление групп квартир по сроку продажи и региону     
categories AS (
SELECT id,CASE
			WHEN days_exposition >=1 AND days_exposition <=30 THEN '1 месяц'
			WHEN days_exposition >=31 AND days_exposition <=90 THEN 'квартал'
			WHEN days_exposition >=91 AND days_exposition <=180  THEN 'полгода'
			WHEN days_exposition >=181 THEN 'больше полугода'
			WHEN days_exposition IS NULL THEN 'Нет данных' 
		END AS active_period,
		CASE 
	   		WHEN city = 'Санкт-Петербург' THEN 'Санкт-Петербург'
	   	ELSE 'ЛенОбласть'
	   END AS region
FROM real_estate.advertisement a
JOIN real_estate.flats f USING(id)
JOIN real_estate.city c USING(city_id)
)
SELECT  region, 
	   active_period, 
	   COUNT(id) AS ads_count,
	   ROUND(COUNT(*)::NUMERIC * 100 / SUM(COUNT(*)) OVER (PARTITION BY region), 2) AS ads_count,             
	   ROUND((AVG(last_price/total_area)::NUMERIC)) AS avg_meter_price,                                  	  
	   ROUND((AVG(total_area)::NUMERIC),2) AS avg_square,                                             		  
	   ROUND((AVG(ceiling_height)::NUMERIC),2) AS avg_ceil_height,											  
	   ROUND((PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms)::NUMERIC),2) AS median_rooms,        		  
	   ROUND((PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony)::NUMERIC),2) AS median_balcony,           
	   ROUND((PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floors_total)::NUMERIC),2) AS median_floor_count,
	   ROUND((COUNT(CASE WHEN is_apartment = 1 THEN 1 END) * 100.0 / COUNT(*)),2) AS apartment_percentage,
	   ROUND((COUNT(CASE WHEN open_plan = 1 THEN 1 END) * 100.0 / COUNT(*)),2) AS open_plan_percentage,
	   ROUND((COUNT(CASE WHEN rooms = 0 THEN 1 END) * 100.0 / COUNT(*)),2) AS studio_percentage,
	   ROUND(AVG(airports_nearest)::NUMERIC) AS airports,
	   ROUND((PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY parks_around3000)::NUMERIC),2) AS median_parks_around,
	   ROUND((PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY ponds_around3000)::NUMERIC),2) AS median_ponds_around
FROM real_estate.flats f
JOIN real_estate.advertisement a USING (id)
JOIN real_estate.city c USING (city_id)
JOIN real_estate."type" t USING(type_id)
JOIN categories USING(id)
WHERE id IN (SELECT * FROM filtered_id) AND t."type" = 'город'
GROUP BY region, active_period
ORDER BY region DESC;

-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    ),
-- вычисление групп квартир по сроку продажи и региону     
categories AS (
SELECT id,CASE
			WHEN days_exposition >=1 AND days_exposition <=30 THEN '1 месяц'
			WHEN days_exposition >=31 AND days_exposition <=90 THEN 'квартал'
			WHEN days_exposition >=91 AND days_exposition <=180  THEN 'полгода'
			WHEN days_exposition >=181 THEN 'больше полугода'
			WHEN days_exposition IS NULL THEN 'Нет данных' 
		END AS active_period,
		CASE 
	   		WHEN city = 'Санкт-Петербург' THEN 'Санкт-Петербург'
	   	ELSE 'ЛенОбласть'
	   END AS region
FROM real_estate.advertisement a
JOIN real_estate.flats f USING(id)
JOIN real_estate.city c USING(city_id)
)
SELECT  region, 
	   active_period, 
	   COUNT(id) AS ads_count,
	   ROUND(COUNT(*)::NUMERIC * 100 / SUM(COUNT(*)) OVER (PARTITION BY region), 2) AS ads_count,             
	   ROUND((AVG(last_price/total_area)::NUMERIC)) AS avg_meter_price,                                  	  
	   ROUND((AVG(total_area)::NUMERIC),2) AS avg_square,                                             		  
	   ROUND((AVG(ceiling_height)::NUMERIC),2) AS avg_ceil_height,											  
	   ROUND((PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms)::NUMERIC),2) AS median_rooms,        		  
	   ROUND((PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony)::NUMERIC),2) AS median_balcony,           
	   ROUND((PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floors_total)::NUMERIC),2) AS median_floor_count,
	   ROUND((COUNT(CASE WHEN is_apartment = 1 THEN 1 END) * 100.0 / COUNT(*)),2) AS apartment_percentage,
	   ROUND((COUNT(CASE WHEN open_plan = 1 THEN 1 END) * 100.0 / COUNT(*)),2) AS open_plan_percentage,
	   ROUND((COUNT(CASE WHEN rooms = 0 THEN 1 END) * 100.0 / COUNT(*)),2) AS studio_percentage,
	   ROUND(AVG(airports_nearest)::NUMERIC) AS airports,
	   ROUND((PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY parks_around3000)::NUMERIC),2) AS median_parks_around,
	   ROUND((PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY ponds_around3000)::NUMERIC),2) AS median_ponds_around
FROM real_estate.flats f
JOIN real_estate.advertisement a USING (id)
JOIN real_estate.city c USING (city_id)
JOIN real_estate."type" t USING(type_id)
JOIN categories USING(id)
WHERE id IN (SELECT * FROM filtered_id) AND t."type" = 'город'
GROUP BY region, active_period
ORDER BY region DESC


-- Задача 2: Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?

WITH limits AS (
    SELECT  
		PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats
	JOIN real_estate.advertisement USING(id)   
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)
    ),
--расчет для месяцев публикаци объявления 
ads_month AS (
	SELECT
		CASE EXTRACT(MONTH FROM first_day_exposition)
            WHEN 1 THEN 'Январь'
            WHEN 2 THEN 'Февраль'
            WHEN 3 THEN 'Март'
            WHEN 4 THEN 'Апрель'
            WHEN 5 THEN 'Май'
            WHEN 6 THEN 'Июнь'
            WHEN 7 THEN 'Июль'
            WHEN 8 THEN 'Август'
            WHEN 9 THEN 'Сентябрь'
            WHEN 10 THEN 'Октябрь'
            WHEN 11 THEN 'Ноябрь'
            WHEN 12 THEN 'Декабрь'
        END AS expo_month,
		COUNT(id) AS expo_ads_count,																		-- кол-во опубликованных объявлений
		ROUND((COUNT(id)::numeric/SUM(COUNT(*)) OVER ())*100,2) AS expo_share,				                -- доля объявлений, опубликованных в этом  месяце
		ROUND((AVG(totaL_area)::numeric),2) AS expo_avg_area,												-- средняя площадь квартир, опубликованных в этом месяце
		ROUND((AVG(last_price/total_area)::numeric),2) AS expo_avg_sqm_price,								-- средняя цена квм квартир, опубликованных в этом месяце 
		RANK() OVER(ORDER BY COUNT(id) desc) AS expo_rank													-- ранг месяца по кол-ву публикаций квартир
	FROM real_estate.flats
	JOIN real_estate.advertisement USING(id)
	JOIN real_estate."type" t USING(type_id)
	WHERE id IN (SELECT * FROM filtered_id)   
			AND EXTRACT(YEAR FROM first_day_exposition) IN (2015, 2016, 2017, 2018) 
			AND t."type" = 'город' 
	GROUP BY expo_month
	ORDER BY expo_month
),
--расчет для месяцев удаления объявления 
ads_removal AS(
	SELECT
		CASE EXTRACT(MONTH FROM first_day_exposition + days_exposition * INTERVAL '1 day')
            WHEN 1 THEN 'Январь'
            WHEN 2 THEN 'Февраль'
            WHEN 3 THEN 'Март'
            WHEN 4 THEN 'Апрель'
            WHEN 5 THEN 'Май'
            WHEN 6 THEN 'Июнь'
            WHEN 7 THEN 'Июль'
            WHEN 8 THEN 'Август'
            WHEN 9 THEN 'Сентябрь'
            WHEN 10 THEN 'Октябрь'
            WHEN 11 THEN 'Ноябрь'
            WHEN 12 THEN 'Декабрь'
        END AS removal_month,  
		COUNT(id) AS removal_ads_count,                                                                 
		ROUND((COUNT(id)::numeric/SUM(COUNT(*)) OVER ())*100,2)AS removal_share,			     
		ROUND((AVG(totaL_area)::numeric),2) AS removal_avg_area,					 
		ROUND((AVG(last_price/total_area)::numeric),2) AS removal_avg_sqm_price,         
		RANK() OVER(ORDER BY COUNT(id) desc) AS removal_rank
	FROM real_estate.flats f
	JOIN real_estate.advertisement a USING(id)
	JOIN real_estate."type" t USING(type_id)
	WHERE id IN (SELECT * FROM filtered_id) 
			AND EXTRACT(YEAR FROM first_day_exposition) IN (2015, 2016, 2017, 2018) 
			AND t."type" = 'город'  
			AND days_exposition IS NOT NULL
	GROUP BY removal_month
	ORDER BY removal_month
	)
	SELECT 
		expo_month  AS MONTH,
		expo_ads_count,
		expo_share,
		removal_ads_count,
		removal_share,
		expo_avg_area,
		expo_avg_sqm_price,
		removal_avg_area,
		removal_avg_sqm_price,
		expo_rank,
		removal_rank
FROM ads_month
JOIN ads_removal ON ads_month.expo_month = ads_removal.removal_month;


-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats
    JOIN real_estate.city c USING (city_id)
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND rooms < (SELECT rooms_limit FROM limits) 
        AND balcony < (SELECT balcony_limit FROM limits) 
        AND ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits) 
        AND city <> 'Санкт-Петербург' 
    )
SELECT 		
		city,                                                                                           -- населенный пункт 
		COUNT(id) AS total_ads,																			-- кол-во объявлений о продаже в населенном пункте 						
		ROUND((COUNT(id)/(SELECT COUNT(id) FROM filtered_id)::NUMERIC)*100,2) AS ads_share,				-- доля объявлений в данном городе от всех объявлений о продаже 
		ROUND((COUNT(days_exposition)/COUNT(id)::NUMERIC*100),2) AS ads_sold,							-- доля снятых объявлений о продаже в данном городе 
		ROUND((AVG(total_area)::NUMERIC),2)AS avg_area,													-- средняя площадь квартиры
		ROUND((AVG(last_price/total_area)::NUMERIC)) AS avg_sqm_price,								-- средняя цена квадратного метра
		ROUND((AVG(days_exposition)::numeric)) AS avg_exposition,												-- средняя длительность продажи квартиры
		ntile(4) OVER(ORDER BY (avg(days_exposition))) AS place												-- ранг 
FROM real_estate.flats f			
JOIN real_estate.advertisement USING (id)
JOIN real_estate.city c USING (city_id)
WHERE id IN (SELECT * FROM filtered_id) AND city <> 'Санкт-Петербург'
GROUP BY city
HAVING COUNT(id) >= 50
ORDER BY avg_exposition ASC  
LIMIT 15;

