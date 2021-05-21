--
-- Created by IntelliJ IDEA.
-- User: Silvia
-- Date: 21/05/2021
-- Time: 13:16
-- To change this template use File | Settings | File Templates.
-- Originally created by Honey for Azerothcore
-- requires ElunaLua module


--Items which are Bind on Equip by default will arrive soulbound in the mail
------------------------------------------------------------------------------------------------
-- ADMIN GUIDE:  -  compile the core with ElunaLua module
--               -  adjust config in this file
--               -  Change the '.send mail' in your webshop to '.senditemandbind'
--               -  add this script to ../lua_scripts/
------------------------------------------------------------------------------------------------

local Config = {}

Config.subject = "Subject"
Config.message = "MailBody"
Config.minGMRankForSend = 2

local storedTargetGuid = {}
local storedItemGuid = {}
local SAB_subRoutine = {}
------------------------------------------
-- NO ADJUSTMENTS REQUIRED BELOW THIS LINE
------------------------------------------

local function SendAndBind(event, player, command)
    local itemGUID
    local item_id
    local item_amount
    local targetGUID
    local SAB_eventId
    local commandArray = SAB_splitString(command)
    if commandArray[1] == "senditemandbind" then
        -- make sure the player is properly ranked
        if player ~= nil then
            if player:GetGMRank() < Config.minGMRankForSend then
                return
            end
        end

        if commandArray[2] == nil or commandArray[3] == nil then
            return "missing argument"
        end

        targetGUID = commandArray[2]
        item_id = commandArray[3]

        if commandArray[4] == nil then
            item_amount = 1
        else
            item_amount = commandArray[4]
        end

        itemGUID = SendMail(Config.subject, Config.message, targetGUID, 0, 61, 0, 0, 0, item_id, item_amount)
        print("itemGUID: "..itemGUID)

        SAB_eventId = CreateLuaEvent(SAB_resumeSubRoutine, 3000, 1)
        print("SAB_eventId: "..SAB_eventId)
        storedTargetGuid[SAB_eventId] = targetGUID
        storedItemGuid[SAB_eventId] = itemGUID

        SAB_subRoutine[SAB_eventId] = coroutine.create(function (targetGUID, itemGUID)
            print("itemGUID2: "..itemGUID)
            CharDBExecute('UPDATE `item_instance` SET `flags` = 1 WHERE `guid` = '..itemGUID..' AND `flags` = 0;')
            CharDBExecute('UPDATE `item_instance` SET `owner_guid` = '..targetGUID..' WHERE `guid` = '..itemGUID..' AND `flags` = 1;')
            return false
         end)
    end
end


PLAYER_EVENT_ON_COMMAND = 42            --(event, player, command)
RegisterPlayerEvent(PLAYER_EVENT_ON_COMMAND, SendAndBind)

function SAB_splitString(inputstr, seperator)
    if seperator == nil then
        seperator = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..seperator.."]+)") do
        table.insert(t, str)
    end
    return t
end

function SAB_resumeSubRoutine(eventId, delay, repeats)
    print("resume")
    coroutine.resume(SAB_subRoutine[eventId],storedTargetGuid[eventId],storedItemGuid[eventId])
    storedTargetGuid[eventId] = nil
    storedItemGuid[eventId] = nil
end