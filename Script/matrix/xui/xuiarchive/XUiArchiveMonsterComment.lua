local XUiArchiveMonsterComment = XLuaUiManager.Register(XLuaUi, "UiArchiveMonsterComment")
local tableInsert = table.insert
local Vector3 = CS.UnityEngine.Vector3
local CSTextManagerGetText = CS.XTextManager.GetText
local ScoreMax = 5
local DifficultyMax = 5
local TagMax = 10

function XUiArchiveMonsterComment:OnEnable()
    self.InfoData = self.Base.CurInfoData
    self.EvaluateData = self.Base.CurEvaluateData
    self:SetPaneBaseInfo()
    self:SetPanelTag()

end

function XUiArchiveMonsterComment:OnDisable()

end

function XUiArchiveMonsterComment:OnStart(base)
    self.Base = base
    self.PaneBaseInfo = {}
    self.PanelTag = {}

    self:SetButtonCallBack()
    self:InitMonsterComment(self.PaneBaseInfo, self.PaneBaseInfoObj)
    self:InitMonsterComment(self.PanelTag, self.PanelTagObj)

    self.PaneBaseInfo.ScoreImg = {
        self.PaneBaseInfo.ScoreImg1,
        self.PaneBaseInfo.ScoreImg2,
        self.PaneBaseInfo.ScoreImg3,
        self.PaneBaseInfo.ScoreImg4,
        self.PaneBaseInfo.ScoreImg5
    }
    self.PaneBaseInfo.LevelImg = {
        self.PaneBaseInfo.LevelImg1,
        self.PaneBaseInfo.LevelImg2,
        self.PaneBaseInfo.LevelImg3,
        self.PaneBaseInfo.LevelImg4,
        self.PaneBaseInfo.LevelImg5
    }
    self.PanelTag.TagItemObj = {
        self.PanelTag.TagItemObj1,
        self.PanelTag.TagItemObj2,
        self.PanelTag.TagItemObj3,
        self.PanelTag.TagItemObj4,
        self.PanelTag.TagItemObj5,
        self.PanelTag.TagItemObj6,
        self.PanelTag.TagItemObj7,
        self.PanelTag.TagItemObj8,
        self.PanelTag.TagItemObj9,
        self.PanelTag.TagItemObj10
    }
end

function XUiArchiveMonsterComment:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
    self.BtnBigClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiArchiveMonsterComment:InitMonsterComment(tmp, obj)
    tmp.Transform = obj.transform
    tmp.GameObject = obj.gameObject
    XTool.InitUiObject(tmp)
end

function XUiArchiveMonsterComment:SetPaneBaseInfo()
    self.PaneBaseInfo.TxtName.text = self.InfoData.Name
    self.PaneBaseInfo.RImgIcon:SetRawImage(self.InfoData.Img)
    self.PaneBaseInfo.ScoreNumTxt.text = CSTextManagerGetText("ChannelNumberLabel", self.EvaluateData and self.EvaluateData.ScoreCount or 0)
    self.PaneBaseInfo.LevelNumTxt.text = CSTextManagerGetText("ChannelNumberLabel", self.EvaluateData and self.EvaluateData.DifficultyCount or 0)

    for index = 1, ScoreMax do
        local isActive = self.EvaluateData and self.EvaluateData.AverageScore and index <= self.EvaluateData.AverageScore
        self.PaneBaseInfo.ScoreImg[index].gameObject:SetActiveEx(isActive)
    end

    for index = 1, DifficultyMax do
        local isActive = self.EvaluateData and self.EvaluateData.AverageDifficulty and index <= self.EvaluateData.AverageDifficulty
        self.PaneBaseInfo.LevelImg[index].gameObject:SetActiveEx(isActive)
    end
end

function XUiArchiveMonsterComment:SetPanelTag()
    self.PanelTag.ImgIcon:SetRawImage(self.InfoData.Icon)
    self.PanelTag.CountList = {}
    for index = 1, TagMax do
        if self.EvaluateData and self.EvaluateData.Tags and self.EvaluateData.Tags[index] then
            if not self.PanelTag.TagItem then self.PanelTag.TagItem = {} end

            if not self.PanelTag.TagItem[index] then
                self.PanelTag.TagItem[index] = {}
                self.PanelTag.TagItem[index].Transform = self.PanelTag.TagItemObj[index].transform
                self.PanelTag.TagItem[index].GameObject = self.PanelTag.TagItemObj[index].gameObject
                XTool.InitUiObject(self.PanelTag.TagItem[index])
            end
            local countList = {}
            countList.Index = index
            countList.Count = self.EvaluateData.Tags[index].Count
            tableInsert(self.PanelTag.CountList, countList)
            self.PanelTag.TagItem[index].TxtNum.text = CSTextManagerGetText("ChannelNumberLabel", self._Control:GetCountUnitChange(self.EvaluateData.Tags[index].Count))
            self.PanelTag.TagItem[index].TxtTag.text = self._Control:GetArchiveTagCfgById(self.EvaluateData.Tags[index].Id).Name
            self.PanelTag.TagItem[index].TxtTag.color = XUiHelper.Hexcolor2Color(self._Control:GetArchiveTagCfgById(self.EvaluateData.Tags[index].Id).Color)
            local bgImg = self._Control:GetArchiveTagCfgById(self.EvaluateData.Tags[index].Id).Bg
            if bgImg then self:SetUiSprite(self.PanelTag.TagItem[index].Bg, bgImg) end
        end
        local isActive = (self.EvaluateData and self.EvaluateData.Tags and self.EvaluateData.Tags[index]) and true or false
        self.PanelTag.TagItemObj[index].gameObject:SetActiveEx(isActive)
    end
    self:SetTagSize()
end

function XUiArchiveMonsterComment:SetTagSize()
    if not self.PanelTag.TagItem then
        return
    end
    local smallCount = math.floor(#self.PanelTag.TagItem / 3)
    local bigCount = math.floor(#self.PanelTag.TagItem / 3)
    local mdCount = #self.PanelTag.TagItem - bigCount - smallCount
    table.sort(self.PanelTag.CountList, function(a, b)
        return a.Count > b.Count
    end)

    for _, count in pairs(self.PanelTag.CountList) do
        if bigCount > 0 then
            self.PanelTag.TagItemObj[count.Index].transform.localScale = Vector3(1.2, 1.2, 1.2)
            bigCount = bigCount - 1
        elseif mdCount > 0 then
            self.PanelTag.TagItemObj[count.Index].transform.localScale = Vector3(1, 1, 1)
            mdCount = mdCount - 1
        elseif smallCount > 0 then
            self.PanelTag.TagItemObj[count.Index].transform.localScale = Vector3(0.8, 0.8, 0.8)
            smallCount = smallCount - 1
        end

    end
end

function XUiArchiveMonsterComment:OnBtnCloseClick()
    self:Close()
end