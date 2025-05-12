local XUiGridTheatre4GeniusCard = require("XUi/XUiTheatre4/Common/XUiGridTheatre4GeniusCard")
local XUiTheatre4ColorResource = require("XUi/XUiTheatre4/System/Resources/XUiTheatre4ColorResource")
---@class XUiTheatre4PopupChooseGenius : XLuaUi
---@field _Control XTheatre4Control
local XUiTheatre4PopupChooseGenius = XLuaUiManager.Register(XLuaUi, "UiTheatre4PopupChooseGenius")

function XUiTheatre4PopupChooseGenius:OnAwake()
    self:RegisterUiEvents()
    self:InitColour()
    self.PanelOn.gameObject:SetActiveEx(false)
    self.PanelOff.gameObject:SetActiveEx(false)
    self.GridGeniusCard.gameObject:SetActiveEx(false)
    ---@type XUiGridTheatre4GeniusCard[]
    self.GridGeniusList = {}
end

function XUiTheatre4PopupChooseGenius:InitColour()
    ---@type XUiTheatre4ColorResource
    self.PanelColour = XUiTheatre4ColorResource.New(self.ListColour, self, function(colorId)
        XLuaUiManager.Open("UiTheatre4Genius", colorId)
    end)
    self.PanelColour:Open()
end

---@param colorId number 颜色id
---@param talentIds number[] 天赋id列表
function XUiTheatre4PopupChooseGenius:OnStart(colorId, talentIds)
    self.ColorId = colorId
    self.TalentIds = talentIds
    -- 标题
    local name = self._Control:GetColorTreeName(self.ColorId)
    self.TxtTitle.text = XUiHelper.GetText("Theatre4GeniusSelectContent", name)
end

function XUiTheatre4PopupChooseGenius:OnEnable()
    self:RefreshNum()
    self:RefreshBuildPoint()
    self:RefreshBtnAndCost()
    self:RefreshGeniusList()
    self:PlayAnimation("PopupEnable")
end

-- 刷新选择数量
function XUiTheatre4PopupChooseGenius:RefreshNum()
    local selectTimes = self.CurSelectGrid and 1 or 0
    local selectLimit = table.nums(self.TalentIds)
    self.TxtNum.text = string.format("%d/%d", selectTimes, selectLimit)
end

-- 刷新建筑点信息
function XUiTheatre4PopupChooseGenius:RefreshBuildPoint()
    -- 建造点图片
    local bpIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.BuildPoint)
    if bpIcon then
        self.ImgEnergy:SetSprite(bpIcon)
    end
    -- 建造点数量
    self.TxtEnergyNum.text = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.BuildPoint)
end

-- 刷新按钮和消耗
function XUiTheatre4PopupChooseGenius:RefreshBtnAndCost()
    -- 剩余刷新次数
    local refreshTimes = self._Control:GetColorTalentRefreshTimes(self.ColorId)
    local refreshLimit = self._Control:GetColorTalentRefreshLimit(self.ColorId)
    -- 当前刷新次数
    local curRefreshTimes = refreshLimit - refreshTimes
    self.BtnRefresh:SetNameByGroup(0, XUiHelper.GetText("Theatre4ChooseGeniusRefresh", curRefreshTimes, refreshLimit))
    -- 刷新消耗
    local cost = self._Control:GetColorTalentRefreshCost(self.ColorId)
    -- 是否满足刷新消耗
    local isEnough = self._Control.AssetSubControl:CheckAssetEnough(XEnumConst.Theatre4.AssetType.Gold, nil, cost, true)
    self.BtnRefresh:SetDisable(refreshTimes <= 0 or not isEnough)
    self.PanelOn.gameObject:SetActiveEx(isEnough)
    self.PanelOff.gameObject:SetActiveEx(not isEnough)
    local panelConsume = isEnough and self.PanelOn or self.PanelOff
    local consumeUi = XTool.InitUiObjectByUi({}, panelConsume)
    local goldIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold)
    local goldCount = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Gold)
    if goldIcon then
        consumeUi.Icon:SetRawImage(goldIcon)
    end
    consumeUi.TxtCosumeNumber.text = cost .. "/" .. goldCount
end

-- 刷新天赋列表
function XUiTheatre4PopupChooseGenius:RefreshGeniusList()
    if XTool.IsTableEmpty(self.TalentIds) then
        return
    end
    for i, talentId in ipairs(self.TalentIds) do
        local grid = self.GridGeniusList[i]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridGeniusCard, self.ListOption)
            grid = XUiGridTheatre4GeniusCard.New(go, self, handler(self, self.OnSelectCallback), handler(self, self.OnYesCallback))
            self.GridGeniusList[i] = grid
        end
        grid:Open()
        grid:Refresh(talentId)
    end
    for i = #self.TalentIds + 1, #self.GridGeniusList do
        self.GridGeniusList[i]:Close()
    end
    self:PlayGeniusAnimation()
end

-- 选择回调
---@param grid XUiGridTheatre4GeniusCard
function XUiTheatre4PopupChooseGenius:OnSelectCallback(grid)
    if self.CurSelectGrid then
        if self.CurSelectGrid:GetTalentId() == grid:GetTalentId() then
            return
        end
        self.CurSelectGrid:SetSelect(false)
        self.CurSelectGrid:SetBtnYes(false)
    end
    grid:SetSelect(true)
    grid:SetBtnYes(true)
    self.CurSelectGrid = grid
    self:RefreshNum()
end

-- 确认回调
function XUiTheatre4PopupChooseGenius:OnYesCallback(talentId)
    -- 选择天赋
    self._Control:SelectTalentRequest(self.ColorId, talentId, function()
        self._Control:CheckNeedOpenNextPopup(self.Name, true)
    end)
end

function XUiTheatre4PopupChooseGenius:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBag, self.OnBtnBagClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBuild, self.OnBtnBuildClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCharacter, self.OnBtnCharacterClick)
    self._Control:RegisterClickEvent(self, self.BtnRefresh, self.OnBtnRefreshClick)
    self._Control:RegisterClickEvent(self, self.BtnMap, self.OnBtnMapClick)
end

-- 背包
function XUiTheatre4PopupChooseGenius:OnBtnBagClick()
    XLuaUiManager.Open("UiTheatre4Bag")
end

-- 建造
function XUiTheatre4PopupChooseGenius:OnBtnBuildClick()
    ---@type UnityEngine.RectTransform
    local rectTransform = self.BtnBuild:GetComponent("RectTransform")
    XLuaUiManager.Open("UiTheatre4BubbleBuild", rectTransform.position, rectTransform.sizeDelta, false)
end

-- 角色
function XUiTheatre4PopupChooseGenius:OnBtnCharacterClick()
    -- 打开角色面板
    self._Control:OpenCharacterPanel()
end

-- 刷新
function XUiTheatre4PopupChooseGenius:OnBtnRefreshClick()
    -- 剩余刷新次数
    local refreshTimes = self._Control:GetColorTalentRefreshTimes(self.ColorId)
    if refreshTimes <= 0 then
        self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4RefreshTimesNotEnough"))
        return
    end
    -- 检查金币是否足够
    local cost = self._Control:GetColorTalentRefreshCost(self.ColorId)
    if not self._Control.AssetSubControl:CheckAssetEnough(XEnumConst.Theatre4.AssetType.Gold, nil, cost) then
        return
    end
    -- 刷新天赋
    self._Control:RefreshTalentRequest(self.ColorId, function()
        if self.CurSelectGrid then
            self.CurSelectGrid:SetSelect(false)
            self.CurSelectGrid:SetBtnYes(false)
            self.CurSelectGrid = nil
        end
        -- 刷新天赋列表
        self.TalentIds = self._Control:GetWaitSlotTalentIds(self.ColorId)
        self:RefreshNum()
        self:RefreshBtnAndCost()
        self:RefreshGeniusList()
    end)
end

function XUiTheatre4PopupChooseGenius:PlayGeniusAnimation()
    local grids = self.GridGeniusList

    if not XTool.IsTableEmpty(grids) then
        for _, grid in pairs(grids) do
            if grid and grid:IsNodeShow() then
                grid:SetAlpha(0)
            end
        end

        XLuaUiManager.SetMask(true, self.Name)
        RunAsyn(function()
            for _, grid in pairs(grids) do
                if grid and grid:IsNodeShow() then
                    grid:PlayGeniusAnimation()

                    asynWaitSecond(0.04)
                end
            end
            XLuaUiManager.SetMask(false, self.Name)
        end)
    end
end

function XUiTheatre4PopupChooseGenius:OnBtnMapClick()
    self._Control:ShowViewMapPanel(XEnumConst.Theatre4.ViewMapType.SelectTalent)
end

function XUiTheatre4PopupChooseGenius:GetPopupArgs()
    return { self.ColorId, self.TalentIds }
end

return XUiTheatre4PopupChooseGenius
