XUiPlayerInfoBase = XClass(nil, "XUiPlayerInfoBase")
local XUiPanelNameplate = require("XUi/XUiNameplate/XUiPanelNameplate")
local TextManager = CS.XTextManager
local BtnGroupIndex = {
    PlayerInfo = 1,
    Collection = 2,
    CharacterList = 3,
    FashionList = 4
}

function XUiPlayerInfoBase:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.BtnCopy.CallBack = function() self:OnBtnCopy() end
    self.Panels = {}
    self.Panels[BtnGroupIndex.PlayerInfo] = XUiPanelInfo.New(self.PanelInfo, self.RootUi)
    self.Panels[BtnGroupIndex.Collection] = XUiPanelCollectionScrollPlayerInfo.New(self.PanelCollectionScroll, self.RootUi)
    self.Panels[BtnGroupIndex.CharacterList] = XUiPanelCharacterList.New(self.PanelCharacterList, self.RootUi)
    self.Panels[BtnGroupIndex.FashionList] = XUiPanelFashionPlayerInfo.New(self.PanelFashionList, self.RootUi)

    self.InfoPanel = self.Panels[BtnGroupIndex.PlayerInfo]
    self.FashionListPanel = self.Panels[BtnGroupIndex.PlayerInfo]
    
    self.UiPanelNameplate = XUiPanelNameplate.New(self.PanelNameplate, self)
    self:UpdateInfo()
    self:InitBtnGroup()
end

function XUiPlayerInfoBase:Destroy()
    XDataCenter.ExhibitionManager.ClearCharacterInfo()
end

function XUiPlayerInfoBase:InitBtnGroup()
    self.CurType = BtnGroupIndex.PlayerInfo
    self.BtnList = {
        [1] = self.BtnPlayerInfo,
        [2] = self.BtnCollection,
        [3] = self.BtnCharacter,
        [4] = self.BtnFashion
    }
    self.BtnGroup:Init(self.BtnList, function(index) self:SelectType(index) end)
    self.BtnGroup:SelectIndex(self.CurType)
end

function XUiPlayerInfoBase:SelectType(index)
    if self.SelectedIndex and self.SelectedIndex == index then
        return
    end

    self.Panels[index]:Show()
    if self.SelectedIndex then
        self.Panels[self.SelectedIndex]:Close()
    end

    self.SelectedIndex = index
end

function XUiPlayerInfoBase:UpdateInfo()
    --更新展示厅的临时数据
    XDataCenter.ExhibitionManager.SetCharacterInfo(self.RootUi.Data.GatherIds)
    local data = self.RootUi.Data
    XUiPLayerHead.InitPortrait(data.CurrHeadPortraitId, data.CurrHeadFrameId, self.Head)
    --------------------------巴别塔徽章显示------------->>>
    local babelTowerIcon = XDataCenter.MedalManager.GetScoreTitleIconById(data.BabelTowerTitleInfo and data.BabelTowerTitleInfo.Id)
    local babelTowerLevel = data.BabelTowerTitleInfo and data.BabelTowerTitleInfo.Score or 0

    if babelTowerIcon then
        self.BabelMedalImage:SetRawImage(babelTowerIcon)
        self.TxtBabelLevel.text = babelTowerLevel
        self.BabelMedalImage.gameObject:SetActiveEx(true)
    else
        self.BabelMedalImage.gameObject:SetActiveEx(false)
    end
    --------------------------巴别塔徽章显示-------------<<<
    self.TxtName.text = XDataCenter.SocialManager.GetPlayerRemark(data.Id, data.Name)
    
    XUiPlayerLevel.UpdateLevel(data.Level, self.level)

    self.TxtId.text = data.Id
    if data.Likes > 9999 then
        self.TxtLikeNum.text = "9999+"
    else
        self.TxtLikeNum.text = data.Likes
    end

    local sign = data.Sign
    if sign == nil or string.len(sign) == 0 then
        local text = TextManager.GetText('CharacterSignTip')
        self.TxtSign.text = text
    else
        self.TxtSign.text = sign
    end

    if data.CurrentWearNameplate ~= 0 then
        self.UiPanelNameplate:UpdateDataById(data.CurrentWearNameplate)
        self.UiPanelNameplate.GameObject:SetActiveEx(true)
    else
        self.UiPanelNameplate.GameObject:SetActiveEx(false)
    end
end

function XUiPlayerInfoBase:OnBtnCopy()
    CS.XAppPlatBridge.CopyStringToClipboard(tostring(self.TxtId.text))
    XUiManager.TipText("Clipboard", XUiManager.UiTipType.Tip)
end

return XUiPlayerInfoBase