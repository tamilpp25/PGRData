local XUiGridStageStar = require("XUi/XUiFubenMainLineDetail/XUiGridStageStar")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiMultiDimRewardTips = XLuaUiManager.Register(XLuaUi, "UiMultiDimRewardTips")

function XUiMultiDimRewardTips:OnAwake()
    -- 记录三个文字描述的Grid
    self.GridStarList = {}
    -- 记录三个物品奖励列表的Grid
    self.GridRewardList1 = {}
    self.GridRewardList2 = {}
    self.GridRewardList3 = {}
    
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
end

function XUiMultiDimRewardTips:OnBtnCloseClick()
    self:Close()
end

function XUiMultiDimRewardTips:OnEnable()
    self:Refresh()
end

-- mStage是 MultiDimSingleFuben表里的Stage信息
function XUiMultiDimRewardTips:OnStart(mStage)
    self.MStage = mStage
    self.StageCfg = XDataCenter.FubenManager.GetStageCfg(mStage.StageId)
end

-- 三个文字描述和三个物品列表分开管理/初始化及刷新
function XUiMultiDimRewardTips:Refresh()
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageCfg.StageId)
    self.StageInfo = stageInfo
    local rewardList = self.MStage.RewardId
    self.TxtRewardDes.text = self.MStage.RewardDes
    for i = 1, 3 do
        -- 刷新填入三个文字描述数据
        local grid = self.GridStarList[i]
        if not grid then
            local ui = self["GridStageStar"..i]
            ui.gameObject:SetActive(true)
            grid = XUiGridStageStar.New(ui)
            self.GridStarList[i] = grid
        end
        grid:Refresh(self.StageCfg.StarDesc[i], stageInfo.StarsMap[i])
        
        -- 刷新填入三个物品奖励列表数据
        local rewards = {}
        if rewardList and next(rewardList) then
            rewards = XRewardManager.GetRewardList(rewardList[i])
        end
        
        for j, item in pairs(rewards) do
            local gridReward = self["GridRewardList"..i][j]
            if not gridReward then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                gridReward = XUiGridCommon.New(self, ui)
                self["GridRewardList"..i][j] = gridReward
            end
            local parent = self["Reward"..i]:Find("Viewport/PanelDropContent")
            gridReward.Transform:SetParent(parent, false)
            gridReward:Refresh(item)
            gridReward.GameObject:SetActive(true)
            gridReward:SetReceived(stageInfo.StarsMap[i])
        end
    end
    self.GridCommon.gameObject:SetActive(false)
end
