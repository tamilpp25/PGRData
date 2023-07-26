XUiGridCollection = XClass(nil, "XUiGridCollection")

local XUiCollectionStyle = require("XUi/XUiMedal/XUiCollectionStyle")

function XUiGridCollection:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CollectionStyleDic = {}    -- Key:收藏品Id  Value:XUiCollectionStyle脚本

    XTool.InitUiObject(self)
    self:AutoAddListener()
end

function XUiGridCollection:AutoAddListener()
    self.BtnSelect.CallBack = function()
        self:OnBtnSelect()
    end
end

function XUiGridCollection:OnBtnSelect()
    XLuaUiManager.Open("UiCollectionTip", self.Chapter, self.InType, function() self:UpdateRedPoint() end)
end

function XUiGridCollection:UpdateGrid(chapter, parent, inType)
    self.Chapter = chapter
    self.InType = inType

    local styleObj = self.CollectionStyleNode.gameObject:LoadPrefab(chapter.PrefabPath)
    self.CollectionStyleDic[chapter.Id] = XUiCollectionStyle.New(styleObj, chapter)

    if chapter.MedalImg ~= nil then
        self.ImgMedalIconlock:SetRawImage(chapter.MedalImg)
    end

    self.TxtMedalName.text = chapter.Name

    local IsLock = chapter.IsLock
    --local rootUi = parent.Base or parent.RootUi

    local qualityImg = XArrangeConfigs.GeQualityPath(chapter.Quality)
    if qualityImg then
        self.ImgQuality:SetSprite(qualityImg)
        --rootUi:SetUiSprite(self.ImgQuality, qualityImg)
        self.ImgQuality.gameObject:SetActiveEx(true)
    else
        self.ImgQuality.gameObject:SetActiveEx(false)
    end

    local levelIcon = XDataCenter.MedalManager.GetLevelIcon(chapter.Id, chapter.Quality)
    if levelIcon then
        self.ImgLevel:SetSprite(levelIcon)
        --rootUi:SetUiSprite(self.ImgLevel, levelIcon)
        self.ImgLevel.gameObject:SetActiveEx(true)
    else
        self.ImgLevel.gameObject:SetActiveEx(false)
    end

    self:ShowLock(IsLock)
    self:ShowRedPoint(XDataCenter.MedalManager.CheckIsNewMedalById(chapter.Id, chapter.Type))
end


function XUiGridCollection:ShowUesing(bShow)
    self.LabelPress.gameObject:SetActiveEx(bShow)
end

function XUiGridCollection:ShowLock(Lock)
    self.LabelLock.gameObject:SetActiveEx(Lock)
end

function XUiGridCollection:UpdateRedPoint()
    self:ShowRedPoint(XDataCenter.MedalManager.CheckIsNewMedalById(self.Chapter.Id, self.Chapter.Type))
end

function XUiGridCollection:ShowRedPoint(bShow)
    if self.Red then
        self.Red.gameObject:SetActiveEx(bShow)
    end
end