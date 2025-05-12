local XUiBiancaTheatreItemGrid = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatreItemGrid")

local XUiChoiceRewardPanel = XClass(nil, "XUiChoiceRewardPanel")

--选择奖励布局
function XUiChoiceRewardPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XUiHelper.InitUiClass(self, ui)
end

function XUiChoiceRewardPanel:Init()
    self.CurrentAdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    self:InitRewardGrids()
    self.GridChallengeBanner.gameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(true)

    if self.TxtProgress2 then
        self.TxtProgress2.gameObject:SetActiveEx(false)
    end
    if XTool.IsNumberValid(self.CurStep:GetIsExTraReward()) and self.TxtProgress2 then
        local chapterId = self.CurrentAdventureManager:GetCurrentChapter():GetCurrentChapterId()
        self.TxtProgress2.gameObject:SetActiveEx(true)
        self.TxtProgress2.text = XBiancaTheatreConfigs.GetChapterExtraRewardDesc(chapterId)
    end
    -- 入场音效
    XDataCenter.BiancaTheatreManager.PlayGetRewardSound(nil, 1)
end

function XUiChoiceRewardPanel:InitRewardGrids()
    self.RewardGridList = {}
    self.CurStep = self.CurrentAdventureManager and self.CurrentAdventureManager:GetCurrentChapter():GetCurStep()    --XAdventureStep
    self.TheatreItemIdList = self.CurStep:GetItemIds()
    for _, theatreItemId in ipairs(self.TheatreItemIdList) do
        local grid = XUiBiancaTheatreItemGrid.New(XUiHelper.Instantiate(self.GridChallengeBanner, self.PanelChapterLis), true)
        XUiHelper.RegisterClickEvent(grid, grid.Btn, function()
            self:OnBtnNextStepClicked(grid)
        end)
        XUiHelper.RegisterClickEvent(grid, grid.BtnSelect, function()
            self:ClickGridFunc(grid)
        end)
        grid:Refresh(theatreItemId)
        --设置按钮名
        grid:SetBtnItemName(XBiancaTheatreConfigs.GetClientConfig("BtnSelectName"))
        --隐藏不需要显示的
        for i = 1, 5 do
            grid["ImgDi" .. i].gameObject:SetActiveEx(false)
        end
        grid.ImgDi.gameObject:SetActiveEx(false)
        grid.Tap.gameObject:SetActiveEx(false)
        table.insert(self.RewardGridList, grid)
    end
end

function XUiChoiceRewardPanel:ClickGridFunc(grid)
    if self.CurSelectGrid then
        self.CurSelectGrid:SetIsSelect(false)
        self.CurSelectGrid:StopSelectAnim()
    end
    self.CurSelectGrid = grid
    grid:SetIsSelect(true)
    grid:PlaySelectAnim()
end

--领取3选1奖励
function XUiChoiceRewardPanel:OnBtnNextStepClicked(grid)
    self.CurrentAdventureManager:RequestSelectItemReward(grid:GetTheatreItemId(), function()
        self.CurStep:SetOverdue(1)
        XDataCenter.BiancaTheatreManager.CheckOpenView(true)
    end)
end

return XUiChoiceRewardPanel