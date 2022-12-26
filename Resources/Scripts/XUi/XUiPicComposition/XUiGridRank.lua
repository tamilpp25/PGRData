XUiGridRank = XClass(nil, "XUiGridRank")

local MAX_SPECIAL_NUM = 3
local FirstIndex = 1
function XUiGridRank:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridRank:SetButtonCallBack()
    self.BtnGo.CallBack = function()
        self:OnBtnGoClick()
    end
end

function XUiGridRank:UpdateGrid(data,index,base,IsInit)
    self.Data = data
    self.Base = base
    self.TxtPlayerName.text = data.UserName
    self.TxtRankScore.text = math.floor(data.Hot)
    self.Index = index

    local btnStatus = self.Base.SelectDataIndex == index and
    CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.BtnGo:SetButtonState(btnStatus)

    self.TxtRankNormal.gameObject:SetActiveEx(index > MAX_SPECIAL_NUM)
    self.ImgRankSpecial.gameObject:SetActiveEx(index <= MAX_SPECIAL_NUM)
    if index <= MAX_SPECIAL_NUM then
        local icon = XDataCenter.FubenBossSingleManager.GetRankSpecialIcon(index)
        self.Base:SetUiSprite(self.ImgRankSpecial, icon)
    else
        self.TxtRankNormal.text = index
    end

    XUiPLayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.Head)

    if not self.Base.IsHaveReward and IsInit then
        if index == FirstIndex then
            self:OnBtnGoClick()
        end
    end
end

function XUiGridRank:OnBtnGoClick()
    self.Base.PanelRankReward.gameObject:SetActiveEx(false)
    self.Base.Phone.gameObject:SetActiveEx(true)
    self.Base.PlayerRankData = self.Data
    self.Base:UpdatePhone()
    self.Base:PlayAnimation("PhoneQieHuan")

    if self.Base.OldButton then
        self.Base.OldButton:SetButtonState(CS.UiButtonState.Normal)
    end
    self.BtnGo:SetButtonState(CS.UiButtonState.Select)
    self.Base.OldButton = self.BtnGo
    self.Base.SelectDataIndex = self.Index
end