--######################## XUiChoiceExRewardGrid ########################
local XUiChoiceExRewardGrid = XClass(nil, "XUiChoiceExRewardGrid")

function XUiChoiceExRewardGrid:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb
    XUiHelper.InitUiClass(self, ui)

    self.Icon.gameObject:SetActiveEx(false)
    self:InitBtn()
    self:InitTap()
end

function XUiChoiceExRewardGrid:InitBtn()
    XUiHelper.RegisterClickEvent(self, self.Btn, self.OnBtnRequst)
    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.OnBtnSelectClick)
    self.Btn:SetName(XBiancaTheatreConfigs.GetClientConfig("BtnSelectName"))
end

function XUiChoiceExRewardGrid:InitTap()
    if self.Tap then self.Tap.gameObject:SetActiveEx(false) end
    if self.Tap1 then self.Tap1.gameObject:SetActiveEx(false) end
    if self.Tap2 then self.Tap2.gameObject:SetActiveEx(false) end
    if self.Tap3 then self.Tap3.gameObject:SetActiveEx(false) end
    if self.Tap4 then self.Tap4.gameObject:SetActiveEx(false) end
end

--id：BiancaTheatreItem表的Id
function XUiChoiceExRewardGrid:Refresh(id, isSelect)
    self.Id = id
    --描述
    self.TxtProgress.text = XBiancaTheatreConfigs.GetItemDescription(id)
    --图标
    self.RImgIcon:SetRawImage(XBiancaTheatreConfigs.GetItemIcon(id))
    --品质
    self.ImgQuality:SetSprite(XBiancaTheatreConfigs.GetEventStepItemQualityIcon(id))
    --名字
    self.TxtDes.text = XBiancaTheatreConfigs.GetItemName(id)
    --名字颜色
    local quality = XBiancaTheatreConfigs.GetEventStepItemQuality(id)
    local nameColor = quality and XBiancaTheatreConfigs.GetClientConfig("QualityTextColor", quality)
    nameColor = nameColor and XUiHelper.Hexcolor2Color(nameColor)
    if nameColor then
        self.TxtDes.color = nameColor
    end
    --是否选中
    self:SetSelectActive(isSelect)
end

function XUiChoiceExRewardGrid:OnBtnRequst()
    XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():RequestSelectItemReward(self:GetId())
end

function XUiChoiceExRewardGrid:OnBtnSelectClick()
    if self.ClickCb then
        self.ClickCb(self)
    end
end

function XUiChoiceExRewardGrid:SetSelectActive(isActive)
    self.Select.gameObject:SetActiveEx(isActive)
    if isActive then
        self:PlaySelectAnim()
    else
        self:StopSelectAnim()
    end
end

function XUiChoiceExRewardGrid:PlaySelectAnim()
    self.GridEnable:Play()
end

function XUiChoiceExRewardGrid:StopSelectAnim()
    self.GridEnable:Stop()
    self.GridEnable:Evaluate()
end

function XUiChoiceExRewardGrid:GetId()
    return self.Id
end


--######################## XUiChoiceExRewardPanel ########################
local XUiChoiceExRewardPanel = XClass(nil, "XUiChoiceExRewardPanel")

--选择额外奖励布局
function XUiChoiceExRewardPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XUiHelper.InitUiClass(self, ui)
end

function XUiChoiceExRewardPanel:Init()
    self.RewardGridList = {}
    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    self.CurChapter = self.AdventureManager:GetCurrentChapter()
    self.CurStep = self.CurChapter:GetCurStep()
    self.ItemIds = self.CurStep:GetItemIds()

    local clickCb = handler(self, self.ClickGridFunc)
    local grid
    for _ in ipairs(self.ItemIds) do
        grid = XUiChoiceExRewardGrid.New(XUiHelper.Instantiate(self.GridChallengeBanner, self.PanelChapterLis), clickCb)
        table.insert(self.RewardGridList, grid)
    end
    self.GridChallengeBanner.gameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(true)

    if self.TxtProgress2 then
        self.TxtProgress2.gameObject:SetActiveEx(false)
    end
    if XTool.IsNumberValid(self.CurStep:GetIsExTraReward()) and self.TxtProgress2 then
        local chapterId = self.CurChapter:GetCurrentChapterId()
        self.TxtProgress2.gameObject:SetActiveEx(true)
        self.TxtProgress2.text = XBiancaTheatreConfigs.GetChapterExtraRewardDesc(chapterId)
    end
    -- 入场音效
    XDataCenter.BiancaTheatreManager.PlayGetRewardSound(nil, 1)
end

function XUiChoiceExRewardPanel:Refresh()
    self.ItemIds = self.CurStep:GetItemIds()

    local isSelect
    for i, itemId in ipairs(self.ItemIds) do
        isSelect = self.CurSelectId == itemId or false
        self.RewardGridList[i]:Refresh(itemId, isSelect)
    end
end

function XUiChoiceExRewardPanel:ClickGridFunc(grid)
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelectActive(false)
    end
    self.CurSelectGrid = grid
    self.CurSelectId = grid:GetId()
    grid:SetSelectActive(true)
end
return XUiChoiceExRewardPanel