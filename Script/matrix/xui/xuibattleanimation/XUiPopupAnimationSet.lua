---@class XUiPopupAnimationSet : XLuaUi 入场结算动画角色自选
local XUiPopupAnimationSet = XLuaUiManager.Register(XLuaUi, "UiPopupAnimationSet")

local DefaultIndex = 0
local Red = 1
local Blue = 2
local Yellow = 3

function XUiPopupAnimationSet:OnAwake()
    self.BtnClose.CallBack = handler(self, self.Close)
    self.BtnTanchuangClose.CallBack = handler(self, self.Close)
    self.BtnSave.CallBack = handler(self, self.OnBtnSaveClick)
end

---@param param TeamAnimationSetParam 自定义参数（比如肉鸽3.0这种非常特殊的功能）
function XUiPopupAnimationSet:OnStart(team, param)
    ---@type XTeam
    self._Team = team
    ---@type TeamAnimationSetParam
    self._Param = param
    self._EntitiyIds = {}
    self._FirstFightPos = 1
    if not XTool.IsTableEmpty(param) then
        self._EntitiyIds = param.EntitiyIds
        self._FirstFightPos = param.FirstFightPos
        self._EnterCgIndex = param.EnterCgIndex or 0
        self._SettleCgIndex = param.SettleCgIndex or 0
    elseif team.TeamData then
        -- 旧编队
        self._EntitiyIds = self._Team.TeamData
        self._FirstFightPos = self._Team.FirstFightPos
        self._EnterCgIndex = self._Team.EnterCgIndex or 0
        self._SettleCgIndex = self._Team.SettleCgIndex or 0
    else
        self._EntitiyIds = self._Team.EntitiyIds
        self._FirstFightPos = self._Team:GetFirstFightPos()
        self._EnterCgIndex = self._Team:GetEnterCgIndex()
        self._SettleCgIndex = self._Team:GetSettleCgIndex()
    end

    self:InitCharacter()
    self:InitEnterGroup()
    self:InitSettleGroup()
end

function XUiPopupAnimationSet:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_ANIM_ENABLE, self.OnAnimationSetChange, self)
end

function XUiPopupAnimationSet:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_ANIM_ENABLE, self.OnAnimationSetChange, self)
end

function XUiPopupAnimationSet:InitCharacter()
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)

    for i = 1, 3 do
        local grid = self["GridTeamRole" .. i]
        if grid then
            local uiObject = {}
            XUiHelper.InitUiClass(uiObject, grid)

            local colorId
            if i == 1 then
                colorId = Blue
            elseif i == 2 then
                colorId = Red
            else
                colorId = Yellow
            end

            local id = self._EntitiyIds[colorId]
            if XTool.IsNumberValid(id) then
                uiObject.PanelNull.gameObject:SetActiveEx(false)
                uiObject.PanelHead.gameObject:SetActiveEx(true)
                local characterIcon
                if XRobotManager.CheckIsRobotId(id) then
                    characterIcon = XRobotManager.GetRobotSmallHeadIcon(id)
                else
                    characterIcon = characterAgency:GetCharSmallHeadIcon(id)
                end
                uiObject.RImgRole:SetRawImage(characterIcon)
            else
                uiObject.PanelNull.gameObject:SetActiveEx(true)
                uiObject.PanelHead.gameObject:SetActiveEx(false)
            end
            uiObject.IconFirstFight.gameObject:SetActiveEx(colorId == self._FirstFightPos)
        end
    end
end

function XUiPopupAnimationSet:InitEnterGroup()
    local btns = {
        self.BtnEntranceRed,
        self.BtnEntranceBlue,
        self.BtnEntranceYellow,
        self.BtnEntranceFirst
    }
    self.PanelEntrance:Init(btns, function(index)
        if index == #btns then
            self._EnterCgIndex = DefaultIndex
        else
            self._EnterCgIndex = index
        end
    end)
    if self._EnterCgIndex == DefaultIndex then
        self.PanelEntrance:SelectIndex(#btns)
    else
        self.PanelEntrance:SelectIndex(self._EnterCgIndex)
    end
end

function XUiPopupAnimationSet:InitSettleGroup()
    local btns = {
        self.BtnExitRed,
        self.BtnExitBlue,
        self.BtnExitYellow,
        self.BtnExit
    }
    self.PanelExit:Init(btns, function(index)
        if index == #btns then
            self._SettleCgIndex = DefaultIndex
        else
            self._SettleCgIndex = index
        end
    end)
    if self._SettleCgIndex == DefaultIndex then
        self.PanelExit:SelectIndex(#btns)
    else
        self.PanelExit:SelectIndex(self._SettleCgIndex)
    end
end

function XUiPopupAnimationSet:OnBtnSaveClick()
    if not XTool.IsTableEmpty(self._Param) then
        if self._Param.OnSave then
            self._Param.OnSave(self._EnterCgIndex, self._SettleCgIndex)
        end
    elseif self._Team.TeamData then
        -- 旧编队
        self._Team.EnterCgIndex = self._EnterCgIndex
        self._Team.SettleCgIndex = self._SettleCgIndex
    else
        self._Team:SetEnterCgIndex(self._EnterCgIndex)
        self._Team:SetSettleCgIndex(self._SettleCgIndex)
        self._Team:Save()
    end
    -- 埋点
    local enterRoleId = 0
    local settleRoleId = 0
    if self._EnterCgIndex ~= DefaultIndex then
        enterRoleId = self._EntitiyIds[self._EnterCgIndex] or 0
    end
    if self._SettleCgIndex ~= DefaultIndex then
        settleRoleId = self._EntitiyIds[self._SettleCgIndex] or 0
    end
    XMVCA.XFuben:RecordAnimationSet(enterRoleId, settleRoleId)
    
    self:Close()
end

function XUiPopupAnimationSet:OnAnimationSetChange()
    if not XMVCA.XFuben:IsFightCgEnable() then
        self:Close()
    end
end

return XUiPopupAnimationSet

---@class TeamAnimationSetParam 自定义参数
---@field EntitiyIds table
---@field FirstFightPos number
---@field EnterCgIndex number
---@field SettleCgIndex number
---@field OnSave function(number,number) 参数1：EnterCgIndex 参数2：SettleCgIndex