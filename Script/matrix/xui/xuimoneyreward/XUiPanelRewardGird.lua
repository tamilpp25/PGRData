local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPanelRewardGird = XClass(nil, "XUiPanelRewardGird")

function XUiPanelRewardGird:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.GridList = {}
    XTool.InitUiObject(self)
    self:InitAutoScript()
    self.GridCommon.gameObject:SetActive(false)
end

--设置内容
function XUiPanelRewardGird:SetupContent(config)
    local curLevel = XDataCenter.BountyTaskManager.GetBountyTaskInfoRankLevel()
    self.TxtValue.text = config.RankName
    self.ImgCur.gameObject:SetActive(curLevel == config.RankLevel)
    self:SetupReward(config.RewardId)
    self.RImgIcon:SetRawImage(config.RankIcon)
    --MoneyTaskIcon3
end

--设置奖励
function XUiPanelRewardGird:SetupReward(rewardId)

    local rewards = XRewardManager.GetRewardList(rewardId)

    if not rewards then
        return
    end

    --显示的奖励
    local start = 0
    if rewards then
        for i, item in ipairs(rewards) do
            start = i
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self.Parent, ui)
                grid.Transform:SetParent(self.PanelRewards, false)
                self.GridList[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActive(true)
        end
    end

    for j = start + 1, #self.GridList do
        self.GridList[j].GameObject:SetActive(false)
    end
end


-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelRewardGird:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelRewardGird:AutoInitUi()
    -- self.TxtValue = self.Transform:Find("TxtValue"):GetComponent("Text")
    -- self.TxtName = self.Transform:Find("TxtName"):GetComponent("Text")
    -- self.PanelRewards = self.Transform:Find("PanelRewards")
    -- self.GridCommon = self.Transform:Find("PanelRewards/GridCommon")
    -- self.PanelSite = self.Transform:Find("PanelRewards/GridCommon/PanelSite")
    -- self.TxtSite = self.Transform:Find("PanelRewards/GridCommon/PanelSite/TxtSite"):GetComponent("Text")
    -- self.ImgCur = self.Transform:Find("ImgCur"):GetComponent("Image")
    -- self.ImgQuality = self.Transform:Find("ImgQuality"):GetComponent("Image")
    -- self.RImgIcon = self.Transform:Find("RImgIcon"):GetComponent("RawImage")
end

function XUiPanelRewardGird:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelRewardGird:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelRewardGird:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelRewardGird:AutoAddListener()
end
-- auto
return XUiPanelRewardGird