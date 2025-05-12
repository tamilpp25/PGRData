local XUiGridTheatre4PopupBuildGenius = require("XUi/XUiTheatre4/Game/Popup/XUiGridTheatre4PopupBuildGenius")
-- 改造界面
---@class XUiTheatre4PopupBuild : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4PopupBuild = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupBuild")

function XUiTheatre4PopupBuild:OnAwake()
    self._Control:RegisterClickEvent(self, self.BtnSure, self.OnBtnSureClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, self.OnBtnCancelClick)
    self.Genius.gameObject:SetActiveEx(false)
    ---@type XUiGridTheatre4PopupBuildGenius[]
    self.RelatedTalentList = {}
end

---@param talentId number 天赋Id
---@param effectId number 效果Id
function XUiTheatre4PopupBuild:OnStart(talentId, effectId)
    self.TalentId = talentId
    self.EffectId = effectId
    if XEnumConst.Theatre4.IsDebug then
        XLog.Warning("<color=#F1D116>Theatre4:</color> XUiTheatre4PopupBuild:OnStart talentId:" .. talentId .. " effectId:" .. effectId)
    end
end

function XUiTheatre4PopupBuild:OnEnable()
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_GAME_PLAY_ANIM_OUT)
    self._Control.MapSubControl:SetMapBuildData(self.EffectId)
    self:RefreshEffectInfo()
    self:RefreshIllustration()
    self:RefreshBtn()
    self:RefreshRelatedTalent()
end

function XUiTheatre4PopupBuild:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE4_BUILD_SELECT_GRID,
    }
end

function XUiTheatre4PopupBuild:OnNotify(event, ...)
    if event == XEventId.EVENT_THEATRE4_BUILD_SELECT_GRID then
        self:RefreshBtn()
    end
end

function XUiTheatre4PopupBuild:OnDisable()
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_GAME_PLAY_ANIM_IN)
    self._Control.MapSubControl:ClearMapBuildData()
end

-- 刷新效果
function XUiTheatre4PopupBuild:RefreshEffectInfo()
    self.TxtDetail.text = self._Control.EffectSubControl:GetEffectOtherDescById(self.EffectId)
end

-- 刷新示意图
function XUiTheatre4PopupBuild:RefreshIllustration()
    local buildId = self._Control.EffectSubControl:GetBuildIdByEffectId(self.EffectId)
    if not XTool.IsNumberValid(buildId) then
        self.PanelTips.gameObject:SetActiveEx(false)
        return
    end
    local skillIcon = self._Control:GetBuildingSkillPicture(buildId)
    if skillIcon then
        self.RImgTips:SetRawImage(skillIcon)
    end
    self.TxtTips.text = self._Control:GetBuildingName(buildId)
end

-- 刷新按钮
function XUiTheatre4PopupBuild:RefreshBtn()
    local isSelect = self._Control.MapSubControl:CheckIsSelectGrid()
    self.BtnSure:SetDisable(not isSelect)
end

-- 刷新关联的天赋
function XUiTheatre4PopupBuild:RefreshRelatedTalent()
    local talentIds = self._Control.MapSubControl:GetRelatedTalentIdsByTalentId(self.TalentId)
    if XTool.IsTableEmpty(talentIds) then
        self.PanelGeniusList.gameObject:SetActiveEx(false)
        return
    end
    self.PanelGeniusList.gameObject:SetActiveEx(true)
    for index, talentId in pairs(talentIds) do
        local grid = self.RelatedTalentList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.Genius, self.PanelGeniusList)
            grid = XUiGridTheatre4PopupBuildGenius.New(go, self)
            self.RelatedTalentList[index] = grid
        end
        grid:Open()
        grid:Refresh(talentId)
    end
    for i = #talentIds + 1, #self.RelatedTalentList do
        self.RelatedTalentList[i]:Close()
    end
end

function XUiTheatre4PopupBuild:OnBtnSureClick()
    -- 是否选中地块
    if not self._Control.MapSubControl:CheckIsSelectGrid() then
        self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4BuildSelectBlock"))
        return
    end
    -- 效果消耗是否满足
    if not self._Control.EffectSubControl:CheckEffectAssetEnough(self.EffectId) then
        return
    end
    -- 建筑数量是否达到上限
    local mapId = self._Control.MapSubControl:GetMapBuildMapId()
    if self._Control.MapSubControl:CheckEffectBuildingCountLimit(mapId, self.EffectId, true) then
        return
    end
    local params = self._Control.MapSubControl:GetMapBuildParams()
    self._Control:UseSkillEffectRequest(self.EffectId, params, function()
        -- 改造成功
        self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4BuildSuccess"))
        self._Control:CheckNeedOpenNextPopup(self.Name, true)
    end)
end

function XUiTheatre4PopupBuild:OnBtnCancelClick()
    self:Close()
end

return XUiTheatre4PopupBuild
