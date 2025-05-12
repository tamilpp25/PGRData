local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiChoiceDifficultyPanel = XClass(nil, "XUiChoiceDifficultyPanel")

--难度选择布局
function XUiChoiceDifficultyPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XUiHelper.InitUiClass(self, ui)
end

function XUiChoiceDifficultyPanel:Init()
    -- 直接获取当前的管理器或者由方法内部创建新的
    self.CurrentAdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local difficulties = self.CurrentAdventureManager:GetDifficulties()
    self.CurrentDifficulty = difficulties[1]
    -- 初始化难度选择标签
    self:InitDifficultyTags(difficulties)
    
    self:RewriteRootUiFunc()
    self.GameObject:SetActiveEx(true)
end

-- 初始化难度标签
function XUiChoiceDifficultyPanel:InitDifficultyTags(difficulties)
    self.BtnDifficulty.gameObject:SetActiveEx(false)
    local buttons = {}
    -- 获取冒险所有开启的难度
    difficulties = difficulties or self.CurrentAdventureManager:GetDifficulties()
    local go, button
    for i, difficulty in ipairs(difficulties) do
        go = XUiHelper.Instantiate(self.BtnDifficulty, self.BtnContent.transform)
        button = go:GetComponent("XUiButton")
        button:SetName(difficulty:GetName())
        button.gameObject:SetActiveEx(true)
        -- 设置禁用状态
        button:SetDisable(not difficulty:GetIsOpen())
        table.insert(buttons, button)
    end
    self.BtnContent:Init(buttons, function(index)
        self:OnBtnDifficultyClicked(index)
    end)

    -- 本地读取难度选择缓存
    self.BtnContent:SelectIndex(self.CurrentAdventureManager:GetDifficultyLocalCacheIndex() or 1)
end

function XUiChoiceDifficultyPanel:Refresh()
    
end

-- difficulty : XAdventureDifficulty
function XUiChoiceDifficultyPanel:OnBtnDifficultyClicked(index)
    local difficulty = self.CurrentAdventureManager:GetDifficulties()[index]
    if not difficulty:GetIsOpen(true) then
        return
    end
    self.CurrentDifficulty = difficulty
    self:RefreshDifficulty(difficulty)

    -- 本地缓存难度选择
    self.CurrentAdventureManager:SaveDifficultyLocalCache(self.CurrentDifficulty)
    self.RootUi:PlayAnimation("QieHuan")
end

-- 刷新当前难度
-- difficulty : XAdventureDifficulty
function XUiChoiceDifficultyPanel:RefreshDifficulty(difficulty) 
    if difficulty == nil then difficulty = self.CurrentDifficulty end
    self.RImgIcon:SetRawImage(difficulty:GetIcon())
    self.TxtName.text = difficulty:GetTitle()
    self.TxtDesc.text = difficulty:GetDesc()
    -- 刷新经验掉落
    self:RefreshRewardList(difficulty:GetRewardIds(), difficulty:GetExpFactor())
end

function XUiChoiceDifficultyPanel:RefreshRewardList(itemIds, factor)
    self.GridBiancaPopUp.gameObject:SetActiveEx(false)
    local child
    local childCount = self.PanelRewardList.childCount
    for i = 0, childCount - 1 do
        child = self.PanelRewardList:GetChild(i)
        child.gameObject:SetActiveEx(false)
    end
    for i = 1, #itemIds do
        if i > childCount then
            child = XUiHelper.Instantiate(self.GridBiancaPopUp, self.PanelRewardList)
        else
            child = self.PanelRewardList:GetChild(i - 1)
        end
        child.gameObject:SetActiveEx(true)
        
        local gridCommon = XUiGridCommon.New(self.RootUi, child)
        local itemId = itemIds[i]
        gridCommon:Refresh(itemId)
        if gridCommon.BtnClick then
            XUiHelper.RegisterClickEvent(gridCommon, gridCommon.BtnClick, function()
                XLuaUiManager.Open("UiBiancaTheatreTips", itemId)
            end)
        end
    end
    self.TxtNumber.text = factor
end

--######################## 重写父UI按钮点击回调 ########################
function XUiChoiceDifficultyPanel:RewriteRootUiFunc()
    XUiHelper.RegisterClickEvent(self, self.RootUi.BtnNextStep, self.OnBtnNextStepClicked)
end

--点击下一步
function XUiChoiceDifficultyPanel:OnBtnNextStepClicked()
    XLuaUiManager.Open("UiBiancaTheatreEndTips", nil, XUiHelper.GetText("TheatreDifficultyTip", self.CurrentDifficulty:GetName()), XUiManager.DialogType.Normal, nil, function()
        self.CurrentAdventureManager:UpdateCurrentDifficulty(self.CurrentDifficulty)
        self.CurrentAdventureManager:RequestStartAdventure(function()
            -- 打开分队选择
            XLuaUiManager.PopThenOpen("UiBiancaTheatreChoice", {UiType = XBiancaTheatreConfigs.UiChoiceType.TeamSelect})
        end)
    end)
end

return XUiChoiceDifficultyPanel