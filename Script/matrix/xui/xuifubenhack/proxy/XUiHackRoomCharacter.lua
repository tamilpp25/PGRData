-- 骇入玩法选人列表界面代理
local XUiHackRoomCharacter = {}

function XUiHackRoomCharacter.InitCharacterTypeBtns(roomCharacterUi, teamCharIdMap, TabBtnIndex)
    roomCharacterUi.BtnTabShougezhe.gameObject:SetActiveEx(false)
    roomCharacterUi.PanelCharacterTypeBtns:SelectIndex(TabBtnIndex.Normal)
end

function XUiHackRoomCharacter.SortList(roomCharacterUi, charIdList)
    local indexDic = {}
    for i, v in ipairs(charIdList) do
        indexDic[v] = i
    end

    table.sort(charIdList, function(a, b)
        local AIsInTeam = roomCharacterUi:IsInTeam(a)
        local BIsInTeam = roomCharacterUi:IsInTeam(b)
        if AIsInTeam ~= BIsInTeam then
            return AIsInTeam
        else
            return indexDic[a] < indexDic[b]
        end
    end)
    return charIdList
end

function XUiHackRoomCharacter.GetCharInfo(roomCharacterUi, charId)
    local charInfo = {}
    if XRobotManager.CheckIsRobotId(charId) then
        charInfo.Id = charId
        charInfo.IsRobot = true
        charInfo.HideTryTag = true
        -- 骇入玩法战力计算特殊处理
        charInfo.Ability = XRobotManager.GetRobotAbility(charId) + XDataCenter.FubenHackManager.GetBuffAbilityBonus()
    else
        charInfo = XMVCA.XCharacter:GetCharacter(charId)
    end
    return charInfo
end

function XUiHackRoomCharacter.OnResetEvent()
    XLuaUiManager.RunMain()
    XDataCenter.FubenHackManager.OnActivityEnd()
end

return XUiHackRoomCharacter