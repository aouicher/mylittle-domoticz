--[[ Install in : ~/domoticz/scripts/lua/script_time_Announce.lua
Source : https://github.com/jmleglise/mylittle-domoticz
Morning and Evening Vocal Announcement
Check every minute to trigger the Announcement :
in the Morning :
- 8h14 - workingDay
- 2min after motion LivingRoom for DayOff
in the evening :
- either first motion detection in "Veranda" after 19h40
- else at 20h04
REQUIRE :
All my other script to manage these variable:
uservariable['mode']
otherdevices['Mode']
uservariable['goodMorning']
otherdevices_svalues['Sonde Perron']
otherdevices_svalues['Motion Veranda']
otherdevices_svalues['Alerte Givre']
otherdevices_svalues['Alerte Meteo']
otherdevices['Alarm Mode']
otherdevices_lastupdate['MailBox']
##########################################################################################]]--
package.path = package.path .. ';' .. '/home/pi/domoticz/scripts/lua/?.lua'
My = require('My_Library')
require('My_Config')




latitude=MY_LATITUDE
longitude=MY_LONGITUDE

local city = "Paris"
local wuAPIkey = WU_API_KEY -- From My_Config.lua file. Your Weather Underground API Key
local dsAPIkey = DS_API_KEY

local eventTable = {   --Exemple
    ["l'anniversaire de xxx"] = "01/01/1970"
}

local eventWeekTable = {   --Exemple
    [1] = {'APERO à 19h00'},
    [2] = {},
    [3] = {},
    [4] = {},
    [5] = {},
    [6] = {},
    [7] = {}
}


month = tonumber(os.date("%m"))
day = tonumber(os.date("%d"))
numOfWeek = tonumber(os.date("%V"))
numOfDay = tonumber(os.date("%w"))


------------------ Check WeekDay Event ------------------
function WeekDayAnnonce(EveningMorning)
    
    local sentenceActivity = ""
    if EveningMorning == "morning" then
        liaison = " Aujourd'hui "
    elseif EveningMorning == "evening" then
        liaison = " Demain "
    end
    sentenceActivity = sentenceActivity .. liaison
    
    for day, event in pairs(eventWeekTable) do
        if ( (numOfDay +1 == day or numOfDay -6 == day) and EveningMorning == "evening" ) or ( numOfDay == day and EveningMorning == "morning" )then
            for i, activity in pairs(event) do
                sentenceActivity = sentenceActivity .. activity.. ". "
            end
        end
    end
    
    return sentenceActivity

end

function morning()
    local sentence = "Bonjour, nous sommes le " .. tonumber(os.date("%d")) .. ". "  -- Good morning, today we are the ..
    
    liaison = " C'est "
    for event, date in pairs(eventTable) do
        if os.date("%d/%m") == date:sub(1, 5)
        then
            sentence = sentence .. liaison .. event .. ". "
            liaison = "et "
        end
    end

    ------------------  Alert meteofrance.com  -- Only for FRANCE. Weather Vigilance  ------------------
    if tonumber(string.sub(otherdevices_svalues['Alerte Meteo'], 1, 1)) == 3 then
        sentence = sentence .. " Attention, Météofrance annonce une vigilance orange de type :" .. string.sub(otherdevices_svalues['Alerte Meteo'], 11) .. "."
    elseif tonumber(string.sub(otherdevices_svalues['Alerte Meteo'], 1, 1)) == 4 then
        sentence = sentence .. " Votre attention sil vous plait. Cest important. Météofrance annonce une alerte rouge de type :" .. string.sub(otherdevices_svalues['Alerte Meteo'], 11) .. "."
    end

    --[[
    ------------------ TEMPERATURE ------------------
    if My.Time_Difference(otherdevices_lastupdate['Sonde Perron']) < 60 * 10 -- mis à jour 10 min max
    then
        str = otherdevices_svalues['Sonde Perron']
        sentence = sentence .. "La température extérieure est de " .. tostring(My.Round(str, 0)) .. " degré." -- outdoor temperature
    else    
        sentence = sentence .. "La sonde extérieure est arrêtée." -- outdoor temperature

    end
    --]]

    ------------------ WEATHER FORECAST ------------------
    json = (loadfile "/home/pi/domoticz/scripts/lua/JSON.lua")()
--    local file = assert(io.popen('curl http://api.wunderground.com/api/' .. wuAPIkey .. '/forecast/lang:FR/q/France/' .. city .. '.json'))


    local file = assert(io.popen('curl "https://api.darksky.net/forecast/' .. dsAPIkey .. '/'..latitude..','..longitude..'?lang=fr&units=ca"'))
      
    local raw = file:read('*all')
    file:close()

    local jsonForecast = json:decode(raw)
 prevision = jsonForecast.hourly.summary  --résume les 12 prochaines heures  (avec 49 heures de data)
 --daily.summary    résume la semaine avec détail pour 8 jours.
 
-- pluie : parcourir hourly.data[0..8h].precipProbability   pour savoir l'heure
 
-- daily.data[0].precipProbability
 
 -- print(prevision)
 
 
 
-- prevision = jsonForecast.forecast.txt_forecast.forecastday[1].fcttext_metric  -- complete prevision

 --## Let's replace the wind directions with words as it is not spoken properly via TTS##

 
    local transformText = {}   -- To adapt the text to a vocal speech
    transformText[#transformText+1] = {"ºc" ,"degré"}
    transformText[#transformText+1] = {" ene " ," "}
    transformText[#transformText+1] = {" ese " , " "}
    transformText[#transformText+1] = {" nne " , " "}
    transformText[#transformText+1] = {" ne " , " "}
    transformText[#transformText+1] = {" n " , " "}
    transformText[#transformText+1] = {" nno " , " "}
    transformText[#transformText+1] = {" no " , " "}
    transformText[#transformText+1] = {" sse " , " "}
    transformText[#transformText+1] = {" se " , " "}
    transformText[#transformText+1] = {" s " , " "}
    transformText[#transformText+1] = {" sso " , " "}
    transformText[#transformText+1] = {" so " , " "}
    transformText[#transformText+1] = {" o " , " "}
    transformText[#transformText+1] = {" ono " , " "}
    transformText[#transformText+1] = {" oso " , " "}
    transformText[#transformText+1] = {" e " , " "}
    transformText[#transformText+1] = {",0" , ""}
    transformText[#transformText+1] = {"partiellement nuageux" , "légèrement nuageux"}
    transformText[#transformText+1] = {"vents soufflant de 15 à 25 km/h." , ""}
    transformText[#transformText+1] = {"vents soufflant de 10 à 25 km/h." , ""}
    transformText[#transformText+1] = {"vents soufflant de 10 à 15 km/h." , ""} --Vent faible
    transformText[#transformText+1] = {"km/h" , "kilomètre heure"}
    transformText[#transformText+1] = {"vents et variables." , "" }

    prevision = string.lower(prevision)
    for k, v in pairs(transformText) do
        prevision = string.gsub(prevision, v[1], v[2])
    end

    sentence = sentence .. " La journée est " .. prevision
    
    
        -------- WeekDayAnnonce ------------------
    sentence = sentence .. WeekDayAnnonce("morning")
    
    ------------------  TRASH DAY MORNING ------------------
    -- Trash day : Mardi vegetaux & ordure / jeudi recyclage &  encombrant (pair) ou  verre (impair) / samedi ordure


    if numOfDay == 2 or numOfDay == 4 or numOfDay == 6
    then
        sentenceTrash = " Je vous rappelle également que "
        if (numOfDay == 4) then
            -- thursday
            if (numOfWeek % 2 == 0) then
                sentenceTrash = sentenceTrash .. " les encombrants et"  --pair
            else
                sentenceTrash = sentenceTrash .. " le verre et"  --impair
            end
            sentenceTrash = sentenceTrash .. " la poubelle jaune sont ramassés ce matin."
        elseif (numOfDay == 2) then
            -- Tuesday
            if (month == 3 and day >= 15) or -- Vegetables trash between the 15 March and the 15 december
            (month == 12 and day <= 15) or
            (month > 3 and month < 12)
            then
                sentenceTrash = sentenceTrash .. " les vegetaux et"
            end
            sentenceTrash = sentenceTrash .. " les poubelles sont ramassées ce matin."
        elseif (numOfDay == 6) then
            -- Saturday
            sentenceTrash = sentenceTrash .. " les poubelles sont ramassées ce matin."
        end
        sentence = sentence .. sentenceTrash
    end
    

    if (numOfDay % 2 == 0) then
        sentence = sentence .. " Je vous souhaite une agréable journée."
    else
        sentence = sentence .. " Passez une bonne journée."
    end
    My.Speak("alexa",sentence, "normal")
    commandArray[#commandArray + 1] = { ['SendNotification'] = 'Annonce du matin#' .. sentence .. '#0' }



end

function evening()
    sentence = ""

    ------------------ Alerte Givre  ------------------
    if tonumber(string.sub(otherdevices_svalues['Alerte Gel'], 1, 1)) > 1 then
        sentence = sentence .. " Il y aura du givre demain matin. Pensez à protéger le parebrise des voitures et les plantes."
    end

    ------------------ Alerte méteo -- Only for FRANCE. Weather Vigilance   ------------------
    if tonumber(string.sub(otherdevices_svalues['Alerte Meteo'], 1, 1)) == 3 then
        sentence = sentence .. " Météofrance annonce une vigilance orange de type :" .. string.sub(otherdevices_svalues['Alerte Meteo'], 11) .. "."
    elseif tonumber(string.sub(otherdevices_svalues['Alerte Meteo'], 1, 1)) == 4 then
        sentence = sentence .. " Météofrance annonce une alerte rouge de type :" .. string.sub(otherdevices_svalues['Alerte Meteo'], 11) .. ". Je répète, c est une alerte rouge. "
    end

    sentence = sentence .. WeekDayAnnonce("evening")
    
    ------------------ Check special Event
    liaison = " Demain c'est "
    for event, date in pairs(eventTable) do
        if tostring(os.date("%d/%m", os.time() + 24 * 60 * 60)) == date:sub(1, 5) -- tomorrow=tostring(os.date("%d:%m",os.time()+24*60*60))
        then
            sentence = sentence .. liaison .. event .. ". "
            liaison = "et "
        end
    end


    ------------------ Alarme : en mode On, pas d'alarme nocturne. C'est l'alarme classique en continue.
    if otherdevices['Alarm Mode'] == 'Night' then
        -- check for security by night
        sentence = sentence .. "l'alarme nocturne est activée à minuit trente."
    elseif otherdevices['Alarm Mode'] == 'Off' then
        -- check for security by night
        sentence = sentence .. "l'alarme nocturne n'est  pas activée."
    end

    ------------------ Prevision Météo
    json = (loadfile "/home/pi/domoticz/scripts/lua/JSON.lua")()

    local file = assert(io.popen('curl "https://api.darksky.net/forecast/' .. dsAPIkey .. '/'..latitude..','..longitude..'?lang=fr&units=ca"'))
    local raw = file:read('*all')
    file:close()

    local jsonForecast = json:decode(raw)

    
--    prevision = jsonForecast.hourly.summary  --résume les 12 prochaines heures  (avec 49 heures de data)

    alerteVent = jsonForecast.daily.data[1].windGust  -- vent cette nuit
    
    if alerteVent > 29 then
        sentence = sentence .. " Attention, cette nuit la météo prévoit des bourasques jusqu'à " .. tostring(My.Round(alerteVent, 0)) .. " kilomètres heure."
    end
    
    
    prevision = jsonForecast.daily.data[2].summary   -- résume la journée de demain
    local high = jsonForecast.daily.data[2].temperatureMax  -- le 2eme index s'appelle 1...
    local low = jsonForecast.daily.data[2].temperatureMin


    
    local maxwind = jsonForecast.daily.data[2].windSpeed
    local precipProbability = jsonForecast.daily.data[2].precipProbability
    local precipIntensity = jsonForecast.daily.data[2].precipIntensity

    sentence=sentence.. " Pour demain, la météo prévoit " .. prevision .. " Avec une température de " .. tostring(My.Round(low, 0)) .. " à " .. tostring(My.Round(high, 0)) .. " degré. "

    if maxwind > 29 then
        sentence = sentence .. " Le vent pourra atteindre " .. maxwind .. " kilomètre heure."
    end


    if precipProbability > 20 then
        sentence = sentence .. " et il est annoncé une probabilité de pluie de " .. precipProbability .. " pourcent et " .. precipIntensity .." milimetre."
    end

--[[
    local snow = jsonForecast.forecast.simpleforecast.forecastday[2].snow_allday.cm
    if snow > 0 then
        sentence = sentence .. " et " .. snow .. " centimètre de neige sont annoncés."
    end
local file = assert(io.popen('curl http://api.wunderground.com/api/' .. wuAPIkey .. '/forecast/lang:FR/q/France/' .. city .. '.json'))
    local raw = file:read('*all')
    file:close()
    local jsonForecast = json:decode(raw)
    local high = jsonForecast.forecast.simpleforecast.forecastday[2].high.celsius  -- le 2eme index s'appelle 1...
    local low = jsonForecast.forecast.simpleforecast.forecastday[2].low.celsius
    local conditions = jsonForecast.forecast.simpleforecast.forecastday[2].conditions
    sentence = sentence .. " Demain, le temps sera " .. conditions .. " avec une température de " .. low .. " à " .. high .. " degré."
    local maxwind = jsonForecast.forecast.simpleforecast.forecastday[2].maxwind.kph
    if maxwind > 29 then
        sentence = sentence .. " Le vent pourra atteindre " .. maxwind .. " kilomètre heure."
    end
    local snow = jsonForecast.forecast.simpleforecast.forecastday[2].snow_allday.cm
    if snow > 0 then
        sentence = sentence .. " et " .. snow .. " centimètre de neige sont annoncés."
    end
]]--

--[[
    ------------------ Check MAIL BOX ------------------
    if uservariables['mode'] == "DayOff" then
        -- Uniquement le samedi, férié , vacance ...
        s = otherdevices_lastupdate['MailBox']
        --tMail= os.time{year=string.sub(s, 1, 4), month=string.sub(s, 6, 7), day=string.sub(s, 9, 10), hour=string.sub(s, 12, 13), min=string.sub(s, 15, 16), sec=string.sub(s, 18, 19)}
        if string.sub(s, 9, 10) == os.date("%d") -- il y a eu du courrier aujourd'hui
        then
            sentence = sentence .. "vous avez reçu du courrier la dernière fois à " .. tonumber(string.sub(s, 12, 13)) .. " heure " .. tonumber(string.sub(s, 15, 16)) .. "."
        end
    end
]]--
    ------------------ TRASH DAY EVENING ------------------
    -- TRash day : Mardi vegetaux & ordure / jeudi recyclage &  encombrant (pair) ou  verre (impair) / samedi ordure
    numOfDay = tonumber(os.date("%w")) + 1  -- on teste pour le lendemain

    if numOfDay == 2 or numOfDay == 4 or numOfDay == 6
    then
        month = tonumber(os.date("%m"))
        day = tonumber(os.date("%d"))
        numOfWeek = tonumber(os.date("%V"))

        sentenceTrash = "Je vous rappelle également que "
        if (numOfDay == 4) then
            -- thursday
            if (numOfWeek % 2 == 0) then
                sentenceTrash = sentenceTrash .. " les encombrants et"  --pair
            else
                sentenceTrash = sentenceTrash .. " le verre et"  --impair
            end
            sentenceTrash = sentenceTrash .. " la poubelle jaune sont ramassés demain matin."
        elseif (numOfDay == 2) then
            -- Tuesday
            if (month == 3 and day >= 15) or -- Vegetables trash between the 15 March and the 15 december
            (month == 12 and day <= 15) or
            (month > 3 and month < 12)
            then
                sentenceTrash = sentenceTrash .. " les végétaux et"
            end
            sentenceTrash = sentenceTrash .. " les poubelles sont ramassées demain matin."
        elseif (numOfDay == 6) then
            -- Saturday
            sentenceTrash = sentenceTrash .. " les poubelles sont ramassées demain matin."
        end
        sentence = sentence .. sentenceTrash

    end

    if sentence ~= "" then
        sentence = "Bonsoir, " .. sentence    -- bonsoir, je vous informe que
        My.Speak("alexa",sentence, "normal")
        commandArray[#commandArray + 1] = { ['SendNotification'] = 'Annonce du soir#' .. sentence .. '#0' }
    end
end

commandArray = {}


local weekday = os.date("%w")   -- jour de la semaine : 0=sunday  to 6=saturday
local time = os.date("*t")
local minutes = time.min + time.hour * 60

--#######  VOCAL ANNOUNCEMENT - MORNING  #######################################################
-- en semaine : 8h14 précise  -- Pour marquer le départ de la maison
-- en DayOff : Entre 1 et 2 minutes après une détection de mouvement sous la véranda (1 seule fois)

-- morning()  -- pour test



if (uservariables['mode'] == "WorkingDay" and time.hour == 7 and time.min == 00)
    or (uservariables['mode'] == "DayOff"
        and (time.hour > 7)
        -- ALEX and My.Time_Difference(otherdevices_lastupdate['Motion LivingRoom']) > 120
        -- ALEX and My.Time_Difference(otherdevices_lastupdate['Motion LivingRoom']) < 180
        and string.sub(uservariables_lastupdate['goodMorning'], 9, 10) ~= os.date("%d")  -- Check Only one time per day
    )
then
    commandArray[#commandArray + 1] = { ['Variable:goodMorning'] = "morning" }  -- something to update "lastupdate"
    morning()
end

-- #############  VOCAL ANNOUNCEMENT - EVENING #################

--evening()

s = uservariables_lastupdate['goodMorning']
tAnnonce = os.time { year = string.sub(s, 1, 4), month = string.sub(s, 6, 7), day = string.sub(s, 9, 10), hour = string.sub(s, 12, 13), min = string.sub(s, 15, 16), sec = string.sub(s, 18, 19) }
t = os.time { year = string.sub(s, 1, 4), month = string.sub(s, 6, 7), day = string.sub(s, 9, 10), hour = 19, min = 03, sec = 50 }

if minutes == 20 * 60 + 30
then
    commandArray[#commandArray + 1] = { ['Variable:goodMorning'] = "evening" }  -- something to update "lastupdate"
    evening()
end
--[[ ALEX
if tAnnonce < t -- Si date de goodmorning est avant 19h03
and minutes > 19 * 60 + 40 -- et qu'il est plus tard que 19h40
and (
   -- lors d'un mouvement	ou 20h05.
     -- DeviceAlexAfaire   My.Time_Difference(otherdevices_lastupdate['Motion Veranda']) < 60
     -- DeviceAlexAfaire   or My.Time_Difference(otherdevices_lastupdate['Motion LivingRoom']) < 60
      
     FIN ALEX

    )
 
then
    commandArray[#commandArray + 1] = { ['Variable:goodMorning'] = "evening" }  -- something to update "lastupdate"
    evening()
end
--]] 

return commandArray
