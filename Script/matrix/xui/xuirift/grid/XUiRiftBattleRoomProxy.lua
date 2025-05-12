local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")

---@class XUiRiftBattleRoomProxy:XUiBattleRoleRoomDefaultProxy
local XUiRiftBattleRoomProxy = XClass(XUiBattleRoleRoomDefaultProxy, "XUiRiftBattleRoomProxy")
local RootUi

--######################## AOP ########################
function XUiRiftBattleRoomProxy:AOPOnStartBefore(rootUi)
    RootUi = rootUi
    local isUnlock = XMVCA.XRift:IsFuncUnlock(XEnumConst.Rift.FuncUnlockId.Attribute)
    rootUi.BtnPanelLoad.gameObject:SetActiveEx(isUnlock)
    rootUi.BtnHandbookBuff.gameObject:SetActiveEx(true)
    rootUi.BtnTemplate.gameObject:SetActiveEx(XMVCA.XRift:IsFuncUnlock(XEnumConst.Rift.FuncUnlockId.Attribute))
    rootUi.BtnBuffDetailClose.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, rootUi.BtnPanelLoad, self.OnBtnAttributeClick)
    XUiHelper.RegisterClickEvent(self, rootUi.BtnHandbookBuff, self.OnBtnHandbookBuffClick)
    XUiHelper.RegisterClickEvent(self, rootUi.BtnTemplate, self.OnBtnTemplateClick)
    XUiHelper.RegisterClickEvent(self, rootUi.BtnBuffDetailClose, self.OnBtnBuffDetailCloseClick)
end

function XUiRiftBattleRoomProxy:GetCharacterViewModelByEntityId(roleId) --加载模型用到的角色id，由于队伍里面存的entityId是大秘境的角色id，要返回真正的charater
    if roleId and roleId > 0 then
        local xRole = XMVCA.XRift:GetEntityRoleById(roleId)
        return xRole and xRole:GetCharacterViewModel()
    end
    return nil
end

function XUiRiftBattleRoomProxy:AOPRefreshRoleInfosAfter(rootUi)
    rootUi.DarkBottom.gameObject:SetActiveEx(true)
    rootUi.ImgSkillLine.gameObject:SetActiveEx(false)
    rootUi.BtnPanelLoad:GetComponent("XUiButton"):ShowReddot(XMVCA.XRift:IsMemberAddPointRed())

    -- 这里刷新角色战力信息
    local team = rootUi.Team
    for index, roleId in pairs(team:GetEntityIds()) do
        local xRole = XMVCA.XRift:GetEntityRoleById(roleId)
        local panelLoad = rootUi["PanelLoad" .. index]
        if panelLoad then
            panelLoad.gameObject:SetActiveEx(not team:CheckIsPosEmpty(index))
        end
        if xRole then
            local text = nil
            if XMVCA.XRift:GetCurrentLoad(xRole) == 0 then
                text = "RiftPluginLoadRed"
            elseif XMVCA.XRift:GetCurrentLoad(xRole) == XMVCA.XRift:GetMaxLoad() then
                text = "RiftPluginLoadBlue"
            else
                text = "RiftPluginLoadYellow"
            end
            local txtLoad = rootUi["TxtLoad" .. index]
            local txtFight = rootUi["TxtFight" .. index]
            if txtLoad then
                txtLoad.text = CS.XTextManager.GetText(text, XMVCA.XRift:GetCurrentLoad(xRole), XMVCA.XRift:GetMaxLoad())
            end
            if txtFight then
                txtFight.text = XMVCA.XRift:GetFinalShowAbility(xRole)
            end
        end
    end

    -- 刷新加点模板信息
    self:RefreshTemplate()

    -- 刷新图鉴加成
    local index = 1
    local datas = XMVCA.XRift:GetHandbookTakeEffectList()
    self._IsEmpty = XTool.IsTableEmpty(datas)
    rootUi:RefreshTemplateGrids(rootUi.GridBuff, datas, rootUi.GridBuff.parent, nil, "", function(grid, data)
        local attr = XMVCA.XRift:GetTeamAttributeEffect(data.AttrId)
        grid.TxtName.text = attr.Name
        grid.ImgBg.gameObject:SetActiveEx(index % 2 == 0)
        if attr.ShowType == XEnumConst.Rift.AttributeFixEffectType.Value then
            grid.TxtNum.text = data.Value
        else
            grid.TxtNum.text = string.format("%s%%", tonumber(string.format("%.1f", data.Value / 100)))
        end
        index = index + 1
    end)
end

function XUiRiftBattleRoomProxy:AOPOnCharacterClickBefore(rootUi, index)
    -- 这里打开大秘境的角色列表界面(不走RoomDetail)
    XLuaUiManager.Open("UiRiftCharacter", false, rootUi.Team, index)
    return true
end

-- 进入战斗
function XUiRiftBattleRoomProxy:EnterFight(team, stageId, challengeCount, isAssist)
    XMVCA.XRift:EnterFight(team)
end

function XUiRiftBattleRoomProxy:RefreshTemplate()
    local uiObject = {}
    local normalUiObject = {}
    local pressUiObject = {}
    XTool.InitUiObjectByUi(uiObject, RootUi.BtnPanelLoad)
    XTool.InitUiObjectByUi(normalUiObject, uiObject.Normal)
    XTool.InitUiObjectByUi(pressUiObject, uiObject.Press)
    local attrTemplate = XMVCA.XRift:GetAttrTemplate(XEnumConst.Rift.DefaultAttrTemplateId)
    for index = 1, XEnumConst.Rift.AttrCnt do
        local attrLevel = attrTemplate:GetAttrLevel(index)
        local attrTxtName = "TxtSu0" .. index
        normalUiObject[attrTxtName].text = tostring(attrLevel)
        uiObject.Normal.transform:Find("Txt0" .. index):GetComponent("Text").text = XMVCA.XRift:GetAttrName(index)
        pressUiObject[attrTxtName].text = tostring(attrLevel)
        uiObject.Press.transform:Find("Txt0" .. index):GetComponent("Text").text = XMVCA.XRift:GetAttrName(index)
    end
    RootUi.BtnPanelLoad:GetComponent("XUiButton"):SetNameByGroup(0, attrTemplate:GetAllLevel())
end

function XUiRiftBattleRoomProxy:OnBtnAttributeClick()
    XLuaUiManager.Open("UiRiftAttribute")
end

function XUiRiftBattleRoomProxy:OnBtnHandbookBuffClick()
    if self._IsEmpty then
        XUiManager.TipError(XUiHelper.GetText("RiftHandbookNoEffect"))
        return
    end
    RootUi.PanelBuffDetail.gameObject:SetActiveEx(true)
    RootUi.BtnBuffDetailClose.gameObject:SetActiveEx(true)
end

function XUiRiftBattleRoomProxy:OnBtnTemplateClick()
    XLuaUiManager.Open("UiRiftTemplate", XEnumConst.Rift.DefaultAttrTemplateId, function(attrTemplateId)
        local attrTemplate = XMVCA.XRift:GetAttrTemplate(attrTemplateId)
        local defaultAttrTemplate = XMVCA.XRift:GetAttrTemplate(XEnumConst.Rift.DefaultAttrTemplateId)
        defaultAttrTemplate:Copy(attrTemplate)
        XMVCA.XRift:RequestSetAttrSet(defaultAttrTemplate, function()
            self:RefreshTemplate()
        end)
    end, nil, true, true)
end

function XUiRiftBattleRoomProxy:OnBtnBuffDetailCloseClick()
    RootUi.PanelBuffDetail.gameObject:SetActiveEx(false)
    RootUi.BtnBuffDetailClose.gameObject:SetActiveEx(false)
end

return XUiRiftBattleRoomProxy