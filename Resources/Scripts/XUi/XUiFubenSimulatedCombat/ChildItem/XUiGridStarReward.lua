local XUiGridStarReward = XClass(nil, "XUiGridStarReward")
 
function XUiGridStarReward:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.GridCommon.gameObject:SetActive(false)

    self.GridList = {}

    self.BtnReceive.CallBack = function() self:OnBtnReceiveClick() end
end

-- auto
function XUiGridStarReward:OnBtnReceiveClick()
 
    if not self.Data.IsFinish then
        return
    end

    XDataCenter.FubenSimulatedCombatManager.GetStarReward(self.Data.Id, function(reward)
        XUiManager.OpenUiObtain(reward, CS.XTextManager.GetText("Award"))
        self:SetBtnAlreadyReceive()
    end)
end

function XUiGridStarReward:Refresh(data)
    self.Data = data
    local ownStars = XDataCenter.FubenSimulatedCombatManager.GetStarProgress()
    local requireStars = data.RequireStar
    local curStars = ownStars > requireStars and requireStars or ownStars
    self.TxtGradeStarNums.text = CS.XTextManager.GetText("GradeStarNum", curStars, requireStars)
    if data.IsFinish then
        self:SetStarsActive(true)
        local isGet = XDataCenter.FubenSimulatedCombatManager.CheckStarRewardGet(data.Id)
        if isGet then
            self:SetBtnAlreadyReceive()
        else
            self:SetBtnActive()
        end
    else
        self:SetStarsActive(false)
        self:SetBtnCannotReceive()
    end

    self:SetupTreasureList()
end

function XUiGridStarReward:SetBtnActive()
    self.BtnReceive.gameObject:SetActive(true)
    self.ImgAlreadyReceived.gameObject:SetActive(false)
    self.ImgCannotReceive.gameObject:SetActive(false)
end

function XUiGridStarReward:SetBtnCannotReceive()
    self.BtnReceive.gameObject:SetActive(false)
    self.ImgAlreadyReceived.gameObject:SetActive(false)
    self.ImgCannotReceive.gameObject:SetActive(true)
end

function XUiGridStarReward:SetBtnAlreadyReceive()
    self.BtnReceive.gameObject:SetActive(false)
    self.ImgAlreadyReceived.gameObject:SetActive(true)
    self.ImgCannotReceive.gameObject:SetActive(false)
end

function XUiGridStarReward:SetStarsActive(flag)
    self.ImgGradeStarActive.gameObject:SetActive(flag)
    self.ImgGradeStarUnactive.gameObject:SetActive(not flag)
end

-- 初始化
function XUiGridStarReward:SetupTreasureList()
    if self.Data == nil or self.Data.RewardId == 0 then
        XLog.Error("treasure have no RewardId ")
        return
    end

    local rewards = XRewardManager.GetRewardList(self.Data.RewardId)
    for i, item in ipairs(rewards) do
        local grid = self.GridList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
            grid = XUiGridCommon.New(self.RootUi, ui)
            grid.Transform:SetParent(self.PanelTreasureContent, false)
            self.GridList[i] = grid
        end
        grid:Refresh(item)
        grid.GameObject:SetActive(true)
    end

    for j = 1, #self.GridList do
        if j > #rewards then
            self.GridList[j].GameObject:SetActive(false)
        end
    end
end

return XUiGridStarReward