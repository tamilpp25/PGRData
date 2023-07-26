---@class XUiGridTerminalMemberItem
local XUiGridTerminalMemberItem = XClass(nil, "XUiGridTerminalMemberItem")

---@param rootUi XUiPanelTerminalMemberSelect
function XUiGridTerminalMemberItem:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.ImgDorm.gameObject:SetActiveEx(false)
    self.CurSelectState = false
end

function XUiGridTerminalMemberItem:Refresh(characterId)
    self.CharacterId = characterId
    -- 是否在队伍中
    local isTeam = XDataCenter.DormQuestManager.CheckDispatchCharacter(characterId)
    self.ImgDorm.gameObject:SetActiveEx(isTeam)
    -- 是否在执勤中
    self.ImgDuty.gameObject:SetActiveEx(false)
    local characterStyleConfig = XDormConfig.GetCharacterStyleConfigById(characterId)
    -- 是否选择
    self.CurSelectState = self.RootUi:CheckSelectMemberContain(characterId)
    self.ImgSelect.gameObject:SetActiveEx(self.CurSelectState)
    -- 角色名
    self.TxtName.text = characterStyleConfig.Name or ""
    -- 头像
    self.ImgIcon:SetRawImage(characterStyleConfig.HeadRoundIcon or "")
    -- 属性
    local questAttribs = characterStyleConfig.QuestAttrib
    for i = 1, 3 do
        local attrib = questAttribs[i]
        local grid = self["Property0" .. i]
        if attrib then
            grid.gameObject:SetActiveEx(true)
            local imgAttrib = XUiHelper.TryGetComponent(grid, "Property", "Image")
            imgAttrib:SetSprite(XDormQuestConfigs.GetQuestAttribIconById(attrib))
        else
            grid.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridTerminalMemberItem:OnBtnClick()
    -- 是否在队伍中
    local isTeam = XDataCenter.DormQuestManager.CheckDispatchCharacter(self.CharacterId)
    if isTeam then
        XUiManager.TipText("DormQuestTerminalMemberInTeam")
        return
    end
    -- 是否已达上限
    if not self.CurSelectState and self.RootUi:CheckSelectMemberLimit() then
        XUiManager.TipText("DormQuestTerminalSurpassTeamNumber")
        return
    end
    self.CurSelectState = not self.CurSelectState
    self.ImgSelect.gameObject:SetActiveEx(self.CurSelectState)
    -- 刷新队伍和属性信息
    self.RootUi:UpdateTeamMemberAndTeamProperty(self.CharacterId, self.CurSelectState)
end

return XUiGridTerminalMemberItem