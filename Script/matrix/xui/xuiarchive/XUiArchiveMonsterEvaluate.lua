local XUiArchiveMonsterEvaluate = XLuaUiManager.Register(XLuaUi, "UiArchiveMonsterEvaluate")
local tableInsert = table.insert
local ScoreMax = 5
local DifficultyMax = 5
local TagMax = 3
local TagAddMax = 3

function XUiArchiveMonsterEvaluate:OnEnable()
    self.InfoData = self.Base.CurInfoData
    self.MySelfEvaluateData = self.Base.CurMySelfEvaluateData
    self:SetPaneBaseInfo()
    self:SetData()
    self:SetPanelTag()

end

function XUiArchiveMonsterEvaluate:OnDisable()

end

function XUiArchiveMonsterEvaluate:OnStart(base, callBack)
    self.Base = base
    self.CallBack = callBack
    self.PaneBaseInfo = {}
    self.PanelTag = {}
    self.TagGroupId = self.Base.Data:GetTagGroupId()
    self:InitMonsterComment(self.PaneBaseInfo, self.PaneBaseInfoObj)
    self:InitMonsterComment(self.PanelTag, self.PanelTagObj)

    self.PaneBaseInfo.ScoreImg = { self.PaneBaseInfo.ScoreImg1, self.PaneBaseInfo.ScoreImg2, self.PaneBaseInfo.ScoreImg3, self.PaneBaseInfo.ScoreImg4, self.PaneBaseInfo.ScoreImg5 }
    self.PaneBaseInfo.LevelImg = { self.PaneBaseInfo.LevelImg1, self.PaneBaseInfo.LevelImg2, self.PaneBaseInfo.LevelImg3, self.PaneBaseInfo.LevelImg4, self.PaneBaseInfo.LevelImg5 }
    self.PaneBaseInfo.ScoreItem = { self.PaneBaseInfo.ScoreItem1, self.PaneBaseInfo.ScoreItem2, self.PaneBaseInfo.ScoreItem3, self.PaneBaseInfo.ScoreItem4, self.PaneBaseInfo.ScoreItem5 }
    self.PaneBaseInfo.LevelItem = { self.PaneBaseInfo.LevelItem1, self.PaneBaseInfo.LevelItem2, self.PaneBaseInfo.LevelItem3, self.PaneBaseInfo.LevelItem4, self.PaneBaseInfo.LevelItem5 }
    self.PanelTag.TagItemObj = { self.PanelTag.TagItemObj1, self.PanelTag.TagItemObj2, self.PanelTag.TagItemObj3 }
    self.PanelTag.TagItemAdd = { self.PanelTag.TagItemAdd1, self.PanelTag.TagItemAdd2, self.PanelTag.TagItemAdd3 }
    self:SetButtonCallBack()
end

function XUiArchiveMonsterEvaluate:OnDestroy()

end

function XUiArchiveMonsterEvaluate:InitMonsterComment(tmp, obj)
    tmp.Transform = obj.transform
    tmp.GameObject = obj.gameObject
    XTool.InitUiObject(tmp)
end

function XUiArchiveMonsterEvaluate:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end

    self.BtnSubmit.CallBack = function()
        self:OnBtnSubmitClick()
    end

    for index = 1, ScoreMax do
        self.PaneBaseInfo.ScoreItem[index].CallBack = function()
            self:OnBtnScoreItemClick(index)
        end
    end

    for index = 1, DifficultyMax do
        self.PaneBaseInfo.LevelItem[index].CallBack = function()
            self:OnBtnLevelItemClick(index)
        end
    end

end

function XUiArchiveMonsterEvaluate:OnBtnScoreItemClick(index)
    self.MyScore = index
    for idx = 1, ScoreMax do
        self.PaneBaseInfo.ScoreImg[idx].gameObject:SetActiveEx(idx <= self.MyScore)
    end
end

function XUiArchiveMonsterEvaluate:OnBtnLevelItemClick(index)
    self.MyDifficulty = index
    for idx = 1, DifficultyMax do
        self.PaneBaseInfo.LevelImg[idx].gameObject:SetActiveEx(idx <= self.MyDifficulty)
    end
end

function XUiArchiveMonsterEvaluate:OnBtnCloseClick()
    self:Close()
end

function XUiArchiveMonsterEvaluate:OnBtnSubmitClick()
    local IsScoreChange = self.MyScore ~= self.OldMyScore
    local IsDifficultyChange = self.MyDifficulty ~= self.OldMyDifficulty
    local IsTagChange = #self.MyTagIds ~= #self.OldMyTagIds

    if not IsTagChange then
        for index, _ in pairs(self.MyTagIds) do
            IsTagChange = IsTagChange or (self.MyTagIds[index] ~= self.OldMyTagIds[index])
            if IsTagChange then
                break
            end
        end
    end

    if IsScoreChange or IsDifficultyChange or IsTagChange then
        self._Control:MonsterGiveEvaluate(self.Base.Data:GetNpcId(self.Base.CurType), self.MyScore, self.MyDifficulty, self.MyTagIds, function()
            self:Close()
        end, self.CallBack)
    else
        self:Close()
    end
    XUiManager.TipText("ArchiveMonsterEvaluateHint")
end

function XUiArchiveMonsterEvaluate:SetData()
    self.MyScore = self.MySelfEvaluateData and self.MySelfEvaluateData.Score or 0
    self.OldMyScore = self.MySelfEvaluateData and self.MySelfEvaluateData.Score or 0
    self.MyDifficulty = self.MySelfEvaluateData and self.MySelfEvaluateData.Difficulty or 0
    self.OldMyDifficulty = self.MySelfEvaluateData and self.MySelfEvaluateData.Difficulty or 0
    self.MyTagIds = {}
    self.OldMyTagIds = {}

    if self.MySelfEvaluateData and not XTool.IsTableEmpty(self.MySelfEvaluateData.Tags) then
        for _, tag in pairs(self.MySelfEvaluateData.Tags) do
            tableInsert(self.MyTagIds, tag)
            tableInsert(self.OldMyTagIds, tag)
        end
    end
end

function XUiArchiveMonsterEvaluate:SetPaneBaseInfo()
    self.PaneBaseInfo.TxtName.text = self.InfoData.Name
    self.PaneBaseInfo.RImgIcon:SetRawImage(self.InfoData.Img)

    for index = 1, ScoreMax do
        self.PaneBaseInfo.ScoreImg[index].gameObject:SetActiveEx(self.MySelfEvaluateData and self.MySelfEvaluateData.Score and index <= self.MySelfEvaluateData.Score)
    end

    for index = 1, DifficultyMax do
        self.PaneBaseInfo.LevelImg[index].gameObject:SetActiveEx(self.MySelfEvaluateData and self.MySelfEvaluateData.Difficulty and index <= self.MySelfEvaluateData.Difficulty)
    end

    self.MyScore = self.MySelfEvaluateData and self.MySelfEvaluateData.Score or 0
    self.OldMyScore = self.MySelfEvaluateData and self.MySelfEvaluateData.Score or 0
    self.MyDifficulty = self.MySelfEvaluateData and self.MySelfEvaluateData.Difficulty or 0
    self.OldMyDifficulty = self.MySelfEvaluateData and self.MySelfEvaluateData.Difficulty or 0
end

function XUiArchiveMonsterEvaluate:SetPanelTag()
    for index = 1, TagMax do
        if self.MyTagIds[index] then
            if not self.PanelTag.TagItem then self.PanelTag.TagItem = {} end

            if not self.PanelTag.TagItem[index] then
                self.PanelTag.TagItem[index] = {}
                self.PanelTag.TagItem[index].Transform = self.PanelTag.TagItemObj[index].transform
                self.PanelTag.TagItem[index].GameObject = self.PanelTag.TagItemObj[index].gameObject
                XTool.InitUiObject(self.PanelTag.TagItem[index])
                self.PanelTag.TagItemObj[index].CallBack = function()
                    self:OnBtnTag()
                end
            end
            
            local archiveTagCfg = self._Control:GetArchiveTagCfgById(self.MyTagIds[index])
            
            self.PanelTag.TagItem[index].TxtTag.text = archiveTagCfg.Name
            self.PanelTag.TagItem[index].TxtTag.color = XUiHelper.Hexcolor2Color(archiveTagCfg.Color)
            local bgImg = archiveTagCfg.Bg
            if bgImg then self:SetUiSprite(self.PanelTag.TagItem[index].Bg, bgImg) end
        end
        self.PanelTag.TagItemObj[index].gameObject:SetActiveEx(self.MyTagIds[index] and true or false)
    end

    for index = 1, TagAddMax do
        if not self.PanelTag.TagItemAdd[index].CallBack then
            self.PanelTag.TagItemAdd[index].CallBack = function()
                self:OnBtnTag()
            end
        end
        self.PanelTag.TagItemAdd[index].gameObject:SetActiveEx(index > #self.MyTagIds)
    end


end

function XUiArchiveMonsterEvaluate:OnBtnTag()
    XLuaUiManager.Open("UiArchiveMonsterSelectTag", self)
end