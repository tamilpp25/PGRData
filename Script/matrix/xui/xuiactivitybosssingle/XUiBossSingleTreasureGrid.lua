local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiBossSingleTreasureGrid = XClass(nil, "XUiBossSingleTreasureGrid")

function XUiBossSingleTreasureGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self.RewardPanelList = {}
end

function XUiBossSingleTreasureGrid:AutoAddListener()
    self.BtnReceive.CallBack = function()
        self:OnBtnReceiveClick()
    end
end

function XUiBossSingleTreasureGrid:OnBtnReceiveClick()
    XDataCenter.FubenActivityBossSingleManager.ReceiveTreasureReward(self.BossStarRewardTemplate.Id, function(reward)
        XUiManager.OpenUiObtain(reward, CS.XTextManager.GetText("Award"))
        self:UpdatePanel()
    end)
end

function XUiBossSingleTreasureGrid:Refresh(rootUi, Id)
    self.RootUi = rootUi
    self.BossStarRewardTemplate = XFubenActivityBossSingleConfigs.GetStarRewardCfg(Id)
    self:UpdatePanel()
end

function XUiBossSingleTreasureGrid:UpdatePanel()
    if self.BossStarRewardTemplate == nil then
        return
    end
    --获取当前的总星数
    local curStarsCount = XDataCenter.FubenActivityBossSingleManager.GetCurStarsCount()
    --获取当前的need星数
    local curNeedCount = self.BossStarRewardTemplate.RequireStar
    if curStarsCount >= curNeedCount then
        self:SetStarsActive(true)
        if XDataCenter.FubenActivityBossSingleManager.CheckRewardIsFinish(self.BossStarRewardTemplate.Id) then
            --已经领取
            self:SetBtnAlreadyReceive()
        else
            self:SetBtnActive()
        end
    else
        self:SetStarsActive(false)
        self:SetBtnCannotReceive()
    end

    --显示星数文本
    self.TxtGradeStarNums.text = CS.XTextManager.GetText("GradeStarNum", curStarsCount, curNeedCount)

    --显示奖励
    local rewards = XRewardManager.GetRewardList(self.BossStarRewardTemplate.RewardId)
    if not rewards then
        return
    end

    for i = 1, #rewards do
        local panel = self.RewardPanelList[i]
        if not panel then
            if #self.RewardPanelList == 0 then
                panel = XUiGridCommon.New(self.RootUi, self.GridCommon)
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                ui.transform:SetParent(self.GridCommon.parent, false)
                panel = XUiGridCommon.New(self.RootUi, ui)
            end
            table.insert(self.RewardPanelList, panel)
        end
        panel:Refresh(rewards[i])
    end
end

function XUiBossSingleTreasureGrid:SetBtnActive()
    self.BtnReceive.gameObject:SetActive(true)
    self.ImgAlreadyReceived.gameObject:SetActive(false)
    self.ImgCannotReceive.gameObject:SetActive(false)
end

function XUiBossSingleTreasureGrid:SetBtnCannotReceive()
    self.BtnReceive.gameObject:SetActive(false)
    self.ImgAlreadyReceived.gameObject:SetActive(false)
    self.ImgCannotReceive.gameObject:SetActive(true)
end

function XUiBossSingleTreasureGrid:SetBtnAlreadyReceive()
    self.BtnReceive.gameObject:SetActive(false)
    self.ImgAlreadyReceived.gameObject:SetActive(true)
    self.ImgCannotReceive.gameObject:SetActive(false)
end

function XUiBossSingleTreasureGrid:SetStarsActive(flag)
    self.ImgGradeStarActive.gameObject:SetActive(flag)
    self.ImgGradeStarUnactive.gameObject:SetActive(not flag)
end

return XUiBossSingleTreasureGrid