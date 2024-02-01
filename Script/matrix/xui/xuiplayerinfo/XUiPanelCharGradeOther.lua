XUiPanelCharGradeOther = XClass(nil, "XUiPanelCharGradeOther")

local Show_Part = {
    [1] = XNpcAttribType.Life,
    [2] = XNpcAttribType.AttackNormal,
    [3] = XNpcAttribType.DefenseNormal,
    [4] = XNpcAttribType.Crit,
}

function XUiPanelCharGradeOther:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self:InitAutoScript()

    self.Star = { self.ImgStar1, self.ImgStar2, self.ImgStar3, self.ImgStar4 }
    self.OnStar = { self.ImgOnStar1, self.ImgOnStar2, self.ImgOnStar3, self.ImgOnStar4 }

    self.Grading = {
        Recruit = 1, --新兵
        RecruitStar = 1, --新兵最大等级
        Picked = 2, --精锐
        PickedStar = 3, --精锐最大等级
        MainForce = 3, --主力
        MainForceStar = 6, --主力最大等级
        Ace = 3, --王牌
        AceStar = 9, --王牌最大等级
        TheChosen = 4, --天选
        TheChosenStar = 13, --天选最大等级
    }

    self.TxtAttrib = {
        [1] = self.TxtAttrib1,
        [2] = self.TxtAttrib2,
        [3] = self.TxtAttrib3,
        [4] = self.TxtAttrib4
    }

    self.TxtNormal = {
        [1] = self.TxtNormal1A,
        [2] = self.TxtNormal2A,
        [3] = self.TxtNormal3A,
        [4] = self.TxtNormal4A
    }
end

function XUiPanelCharGradeOther:InitAutoScript()
    self:AutoInitUi()
    XTool.InitUiObject(self)
end

function XUiPanelCharGradeOther:AutoInitUi()
    self.PanelParts = self.Transform:Find("PanelGrades/PanelParts")
    self.DetailPanel = self.Transform:Find("PanelGrades/DetailPanel")
    self.ImgMax1 = self.Transform:Find("PanelGrades/ImgMax1"):GetComponent("Image")
    self.PanelStarGoup = self.Transform:Find("PanelGrades/PanelGrade/PanelStarGoup")
    self.PanelPartsItems = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems")
    self.RImgIconTitle = self.Transform:Find("PanelGrades/PanelGrade/RImgIconTitle"):GetComponent("RawImage")
    self.TxtCurPorperty = self.Transform:Find("PanelGrades/PanelParts/TxtCurPorperty")
    self.TxtPropertyPreview = self.Transform:Find("PanelGrades/PanelParts/TxtPropertyPreview")

    self.GridPart1 = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart1")
    self.TxtAttrib1 = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart1/Image/TxtAttrib1"):GetComponent("Text")
    self.TxtNormal1A = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart1/Image/TxtNormal1"):GetComponent("Text")
    self.TxtLevel1A = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart1/Image/TxtLevel1"):GetComponent("Text")

    self.GridPart2 = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart2")
    self.TxtAttrib2 = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart2/Image/TxtAttrib2"):GetComponent("Text")
    self.TxtNormal2A = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart2/Image/TxtNormal2"):GetComponent("Text")
    self.TxtLevel2A = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart2/Image/TxtLevel2"):GetComponent("Text")

    self.GridPart3 = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart3")
    self.TxtAttrib3 = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart3/Image/TxtAttrib3"):GetComponent("Text")
    self.TxtNormal3A = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart3/Image/TxtNormal3"):GetComponent("Text")
    self.TxtLevel3A = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart3/Image/TxtLevel3"):GetComponent("Text")

    self.GridPart4 = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart4")
    self.TxtAttrib4 = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart4/Image/TxtAttrib4"):GetComponent("Text")
    self.TxtNormal4A = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart4/Image/TxtNormal4"):GetComponent("Text")
    self.TxtLevel4A = self.Transform:Find("PanelGrades/PanelParts/PanelPartsItems/GridPart4/Image/TxtLevel4"):GetComponent("Text")

    self.ImgStar1 = self.Transform:Find("PanelGrades/PanelGrade/PanelStarGoup/Star1/ImgStar1"):GetComponent("Image")
    self.ImgOnStar1 = self.Transform:Find("PanelGrades/PanelGrade/PanelStarGoup/Star1/ImgOnStar1"):GetComponent("Image")

    self.ImgStar2 = self.Transform:Find("PanelGrades/PanelGrade/PanelStarGoup/Star2/ImgStar2"):GetComponent("Image")
    self.ImgOnStar2 = self.Transform:Find("PanelGrades/PanelGrade/PanelStarGoup/Star2/ImgOnStar2"):GetComponent("Image")

    self.ImgStar3 = self.Transform:Find("PanelGrades/PanelGrade/PanelStarGoup/Star3/ImgStar3"):GetComponent("Image")
    self.ImgOnStar3 = self.Transform:Find("PanelGrades/PanelGrade/PanelStarGoup/Star3/ImgOnStar3"):GetComponent("Image")

    self.ImgStar4 = self.Transform:Find("PanelGrades/PanelGrade/PanelStarGoup/Star4/ImgStar4"):GetComponent("Image")
    self.ImgOnStar4 = self.Transform:Find("PanelGrades/PanelGrade/PanelStarGoup/Star4/ImgOnStar4"):GetComponent("Image")

    self.PanelGradeUpgrade = self.Transform:Find("PanelGradeUpgrade")
end

function XUiPanelCharGradeOther:ShowPanel(character)
    self.GameObject:SetActiveEx(true)
    self.PanelPartsItems.gameObject:SetActiveEx(true)
    self.TxtCurPorperty.gameObject:SetActiveEx(true)

    self.DetailPanel.gameObject:SetActiveEx(false)
    self.TxtLevel1A.gameObject:SetActiveEx(false)
    self.TxtLevel2A.gameObject:SetActiveEx(false)
    self.TxtLevel3A.gameObject:SetActiveEx(false)
    self.TxtLevel4A.gameObject:SetActiveEx(false)
    self.TxtPropertyPreview.gameObject:SetActiveEx(false)
    self.PanelGradeUpgrade.gameObject:SetActiveEx(false)
    self.GradeQiehuan:PlayTimelineAnimation()

    self:UpdateGradeData(character)
end

function XUiPanelCharGradeOther:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelCharGradeOther:UpdateGradeData(character)
    local curGradeConfig = XMVCA.XCharacter:GetGradeTemplates(character.Id, character.Grade)
    local curAttrib = XAttribManager.GetBaseAttribs(curGradeConfig.AttrId)
    self.RImgIconTitle:SetRawImage(curGradeConfig.GradeBigIcon)
    self:UpdateStarSprite(curGradeConfig.NoStar, curGradeConfig.Star)

    for i = 1, 4 do
        local name = XAttribManager.GetAttribNameByIndex(Show_Part[i])
        local attribType = Show_Part[i]
        self.TxtAttrib[i].text = name
        self.TxtNormal[i].text = XMath.ToMinInt(FixToDouble(curAttrib[attribType]))
    end

    if character.Grade > self.Grading.TheChosenStar then
        self:UpdateStarInfo(self.Grading.TheChosen, character.Grade - self.Grading.AceStar)
        return
    end

    if character.Grade > self.Grading.AceStar then
        self:UpdateStarInfo(self.Grading.TheChosen, character.Grade - self.Grading.AceStar)
        return
    end

    if character.Grade > self.Grading.MainForceStar then
        self:UpdateStarInfo(self.Grading.Ace, character.Grade - self.Grading.MainForceStar)
        return
    end

    if character.Grade > self.Grading.PickedStar then
        self:UpdateStarInfo(self.Grading.MainForce, character.Grade - self.Grading.PickedStar)
        return
    end

    if character.Grade > self.Grading.RecruitStar then
        self:UpdateStarInfo(self.Grading.Picked, character.Grade - self.Grading.RecruitStar)
        return
    end

    if character.Grade <= self.Grading.RecruitStar then
        self:UpdateStarInfo(self.Grading.Recruit, character.Grade)
        return
    end
end

function XUiPanelCharGradeOther:UpdateStarSprite(starSprite, onStarSprite)
    for i = 1, #self.Star do
        self.Parent:SetUiSprite(self.Star[i], starSprite)
        self.Parent:SetUiSprite(self.OnStar[i], onStarSprite)
    end
end

function XUiPanelCharGradeOther:UpdateStarInfo(index, onIndex)
    for i = 1, #self.Star do
        self.Star[i].gameObject:SetActiveEx(false)
        self.OnStar[i].gameObject:SetActiveEx(false)
    end

    if onIndex > #self.Star then
        for i = 1, #self.Star do
            self.Star[i].gameObject:SetActiveEx(false)
            self.OnStar[i].gameObject:SetActiveEx(true)
        end
        return
    end

    for i = 1, index do
        self.Star[i].gameObject:SetActiveEx(true)
    end

    for i = 1, onIndex do
        self.OnStar[i].gameObject:SetActiveEx(true)
    end
end