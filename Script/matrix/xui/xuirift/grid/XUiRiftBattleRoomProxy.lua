local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiRiftBattleRoomProxy = XClass(XUiBattleRoleRoomDefaultProxy, "XUiRiftBattleRoomProxy")

--######################## AOP ########################
function XUiRiftBattleRoomProxy:AOPOnStartBefore(rootUi)
    local isUnlock = XDataCenter.RiftManager.IsFuncUnlock(XRiftConfig.FuncUnlockId.Attribute)
    rootUi.BtnPanelLoad.gameObject:SetActiveEx(isUnlock)
    XUiHelper.RegisterClickEvent(self, rootUi.BtnPanelLoad, self.OnBtnAttributeClick)
end

function XUiRiftBattleRoomProxy:GetCharacterViewModelByEntityId(roleId) --加载模型用到的角色id，由于队伍里面存的entityId是大秘境的角色id，要返回真正的charater
    if roleId and roleId > 0 then
        local xRole = XDataCenter.RiftManager.GetEntityRoleById(roleId)
        return xRole:GetCharacterViewModel()
    end
    return nil
end

function XUiRiftBattleRoomProxy:AOPRefreshRoleInfosAfter(rootUi)
    rootUi.DarkBottom.gameObject:SetActiveEx(true)
    rootUi.ImgSkillLine.gameObject:SetActiveEx(false)

    -- 这里刷新角色战力信息
    local team = rootUi.Team
    for index, roleId in pairs(team:GetEntityIds()) do
        local xRole = XDataCenter.RiftManager.GetEntityRoleById(roleId)
        rootUi["PanelLoad"..index].gameObject:SetActiveEx(not team:CheckIsPosEmpty(index))
        if xRole then
            local text = nil
            if xRole:GetCurrentLoad() == 0 then
                text = "RiftPluginLoadRed"
            elseif xRole:GetCurrentLoad() == XDataCenter.RiftManager.GetMaxLoad() then
                text = "RiftPluginLoadBlue"
            else
                text = "RiftPluginLoadYellow"
            end
            rootUi["TxtLoad"..index].text = CS.XTextManager.GetText(text, xRole:GetCurrentLoad(), XDataCenter.RiftManager.GetMaxLoad())
            rootUi["TxtTrend"..index].text = xRole:GetAttrTypeName()
            rootUi["TxtFight"..index].text = xRole:GetFinalShowAbility()
        end
    end

    -- 刷新加点模板信息
    local normal = rootUi.BtnPanelLoad:GetObject("Normal")
    local press = rootUi.BtnPanelLoad:GetObject("Press")
    local attrTemplate = XDataCenter.RiftManager.GetAttrTemplate(XRiftConfig.DefaultAttrTemplateId)
    for index = 1, XRiftConfig.AttrCnt do
        local attrLevel = attrTemplate:GetAttrLevel(index)
        local attrTxtName = "TxtSu0" .. index
        normal:GetObject(attrTxtName).text = tostring(attrLevel)
        normal.transform:Find("Txt0"..index):GetComponent("Text").text = XRiftConfig.GetAttrName(index)
        press:GetObject(attrTxtName).text = tostring(attrLevel)
        press.transform:Find("Txt0"..index):GetComponent("Text").text = XRiftConfig.GetAttrName(index)
    end
    rootUi.BtnPanelLoad:GetComponent("XUiButton"):SetNameByGroup(0, attrTemplate:GetAllLevel())
end

function XUiRiftBattleRoomProxy:AOPOnCharacterClickBefore(rootUi, index)
    -- 这里打开大秘境的角色列表界面(不走RoomDetail)
    XLuaUiManager.Open("UiRiftCharacter", false, rootUi.Team, index)
    return true
end

-- 进入战斗
function XUiRiftBattleRoomProxy:EnterFight(team, stageId, challengeCount, isAssist)
    XDataCenter.RiftManager.EnterFight(team)
end

function XUiRiftBattleRoomProxy:OnBtnAttributeClick()
    XLuaUiManager.Open("UiRiftAttribute")
end

return XUiRiftBattleRoomProxy