local XUiPanelCollectionScrollPlayerInfo = XClass(nil, "XUiPanelCollectionScrollPlayerInfo")

local XUiCollectionWallOther = require("XUi/XUiCollectionWall/XUiCollectionWallOther")
local XCollectionWall = require("XEntity/XCollectionWall/XCollectionWall")

local TextManager = CS.XTextManager

function XUiPanelCollectionScrollPlayerInfo:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)

    self.CollectionList = {}    --拥有的收藏品
    self.CollectionWall = {}
    self.GridCollection.gameObject:SetActiveEx(false)

    self.BtnCollectionWall.CallBack = function()
        self:OnBtnCollectionWallClick()
    end
end

function XUiPanelCollectionScrollPlayerInfo:Show()
    self.GameObject:SetActiveEx(true)

    if self.RootUi.IsOpenFromSetting then
        --从设置面板进入，使用预览数据
        self.CollectionList = self.RootUi.Data.CollectionShow
        self.CollectionWall = self.RootUi.Data.CollectionWall
        self:Refresh(true)
    else
        self:Refresh()
        if self:HasPermission() then
            XDataCenter.PlayerInfoManager.RequestPlayerTitleData(self.RootUi.Data.Id, function(data)
                XDataCenter.MedalManager.SetSpecificMaxScore(data.Titles)
                self.CollectionList = data.Titles
                self.CollectionWall = {}
                for _, wall in pairs(data.Walls) do
                    local collectionWall = XCollectionWall.New(wall.Id)
                    collectionWall:UpdateDate(
                            { Id = wall.Id,
                              PedestalId = wall.PedestalId,
                              BackgroundId = wall.BackgroundId,
                              CollectionSetInfos = wall.CollectionSetInfos
                            })
                    table.insert(self.CollectionWall, collectionWall)
                end
                self:Refresh(true)
            end)
        end
    end
end

function XUiPanelCollectionScrollPlayerInfo:Refresh(hasPermission)
    local hasCollection = self:HasCollection()
    self:SetContent(hasPermission, hasCollection)
end

function XUiPanelCollectionScrollPlayerInfo:SetContent(hasPermission, hasCollection)
    local isLoadData = hasPermission and hasCollection

    if not isLoadData then
        self.PanelCollectionNone.gameObject:SetActiveEx(true)
        self.BtnCollectionWall.gameObject:SetActiveEx(false)
        if not hasPermission then
            self.EmptyText.text = TextManager.GetText("PlayerInfoWithoutPermission")
        else
            self.EmptyText.text = TextManager.GetText("CollectionWallEmpty")
        end
    else
        self.BtnCollectionWall.gameObject:SetActiveEx(true)
        self.PanelCollectionNone.gameObject:SetActiveEx(false)

        self.OtherPlayerScoreTitleList = XDataCenter.MedalManager.CreateOtherPlayerScoreTitleList(self.CollectionList)

        local pedestalId = self.CollectionWall[1]:GetPedestalId()
        local backgroundId = self.CollectionWall[1]:GetBackgroundId()
        local collectionInfo = self.CollectionWall[1]:GetCollectionSetInfos()
        local scoreTitleDic = {}
        for _, data in pairs(self.OtherPlayerScoreTitleList) do
            scoreTitleDic[data.Id] = data
        end
        self.WallPanel = XUiCollectionWallOther.New(self.PanelWall, pedestalId, backgroundId, collectionInfo, scoreTitleDic)
    end
end

--==============================--
--desc: 是否拥有权限查看信息
--@return: 有true，无false
--==============================--
function XUiPanelCollectionScrollPlayerInfo:HasPermission()
    self.AppearanceSettingInfo = self.RootUi.Data.AppearanceSettingInfo and
            self.RootUi.Data.AppearanceSettingInfo.TitleType or XUiAppearanceShowType.ToSelf

    local isFriend = XDataCenter.SocialManager.CheckIsFriend(self.RootUi.Data.Id)
    local hasPermission = (self.AppearanceSettingInfo == XUiAppearanceShowType.ToAll)
            or (self.AppearanceSettingInfo == XUiAppearanceShowType.ToFriend and isFriend)
    return hasPermission
end

--==============================--
--desc: 是否拥有收藏品
--@return: 有true,无false
--==============================--
function XUiPanelCollectionScrollPlayerInfo:HasCollection()
    local length = #self.CollectionWall
    return length >= 1
end

function XUiPanelCollectionScrollPlayerInfo:OnBtnCollectionWallClick()
    XLuaUiManager.Open("UiCollectionWallView", self.CollectionWall, XDataCenter.MedalManager.InType.OtherPlayer, self.OtherPlayerScoreTitleList)
end

function XUiPanelCollectionScrollPlayerInfo:Close()
    self.CollectionList = {}
    self.AppearanceSettingInfo = nil
    self.GameObject:SetActiveEx(false)
end

return XUiPanelCollectionScrollPlayerInfo