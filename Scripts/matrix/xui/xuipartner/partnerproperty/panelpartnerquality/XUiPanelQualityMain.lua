local XUiPanelQualityMain = XClass(nil, "XUiPanelQualityMain")
local STAR_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("0F70BCFF"),
    [false] = XUiHelper.Hexcolor2Color("6A6A6AFF"),
}

function XUiPanelQualityMain:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    XTool.InitUiObject(self)

    self:InitPanelStarPoint()
    self:InitPanelItems()
end

function XUiPanelQualityMain:InitPanelStarPoint()
    self.StarList = {
        self.PanelStarPoint:GetObject("Point1"),
        self.PanelStarPoint:GetObject("Point2"),
        self.PanelStarPoint:GetObject("Point3"),
        self.PanelStarPoint:GetObject("Point4"),
        self.PanelStarPoint:GetObject("Point5"),
    }

    self.PanelStarPoint:GetObject("ProgressCircle").fillAmount = 0
    self.PanelStarPoint:GetObject("ProgressCirclePreview").fillAmount = 0
end

function XUiPanelQualityMain:InitPanelItems()
    self.BtnUpgrade.CallBack = function()
        self:OnBtnUpgrade()
    end
end

function XUiPanelQualityMain:OnBtnUpgrade()
    local pageDatas = XDataCenter.PartnerManager.GetPartnerQualityUpDataList(self.Data:GetId())
    local canCompose = XDataCenter.PartnerManager.CheckComposeRedByTemplateId(self.Data:GetTemplateId())
    if #pageDatas == 0 and not canCompose then
        XUiManager.TipText("PartnerPartnerAndClipNotEnough")
    else
        self.Base:OpenStarPanel()
    end
end

function XUiPanelQualityMain:UpdatePanel(data)---刷新掉这个
    self.Data = data
    self:UpdatePanelGrowUp()
    self:UpdatePanelStarPoint(false)
    self.GameObject:SetActiveEx(true)
end

function XUiPanelQualityMain:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelQualityMain:UpdatePanelGrowUp()
    local nextQuality = self.Data:GetQuality() + 1
    local icon = XCharacterConfigs.GetCharacterQualityIcon(nextQuality)
    self.PanelGrowUp:GetObject("TxtSkill").text = self.Data:GetQualitySkillColumnCount()
    self.PanelGrowUp:GetObject("TxtSkillNext").text = self.Data:GetQualitySkillColumnCount(nextQuality)
    self.PanelGrowUp:GetObject("RawImageQuality"):SetRawImage(icon)
end

function XUiPanelQualityMain:UpdatePanelStarPoint(IsAnime)
    local addClipCount = 0
    local exQuality = self.Data:GetQuality() - 1
    exQuality = exQuality >= self.Data:GetInitQuality() and exQuality or 0
    local exMaxClipCount = exQuality > 0 and self.Data:GetClipMaxCount(exQuality) or 0
    
    local curClipCount = self.Data:GetStarSchedule()
    local nextClipCount = self.Data:GetStarSchedule() + addClipCount
    local maxClipCount = self.Data:GetClipMaxCount()
    
    local curStar = self.Data:GetCanActivateStarCount(nil, curClipCount)
    local nextStar = self.Data:GetCanActivateStarCount(nil, nextClipCount)
    local maxStarCount = self.Data:GetMaxStarCount()
    local attribList = self.Data:GetQualityStarAttribs()
    local qualityIcon = XCharacterConfigs.GetCharQualityIcon(self.Data:GetQuality())
    
    self.IsSelectClipFull = nextClipCount >= maxClipCount
    
    local curP = (curClipCount - exMaxClipCount) / (maxClipCount - exMaxClipCount)
    local needP = (nextClipCount - exMaxClipCount) / (maxClipCount - exMaxClipCount)
    if IsAnime then
        self.PanelStarPoint:GetObject("ProgressCircle"):DOFillAmount(curP, DOFillTime)
        self.PanelStarPoint:GetObject("ProgressCirclePreview"):DOFillAmount(needP, DOFillTime)
    else
        self.PanelStarPoint:GetObject("ProgressCircle").fillAmount = curP
        self.PanelStarPoint:GetObject("ProgressCirclePreview").fillAmount = needP
    end
    
    self.PanelStarPoint:GetObject("BigRImgQuality"):SetRawImage(qualityIcon)
    
    for index = 1, maxStarCount do
        local star = self.StarList[index]
        if star then
            local IsActivate = index <= curStar
            local IsPreview = not IsActivate and (index <= nextStar)
            local IsLock = not IsActivate and not IsPreview
            local attrib = attribList[index]
            
            local attribInfoList = XDataCenter.PartnerManager.ConstructPartnerAttrMap(attrib, false, true)
            for _,info in pairs(attribInfoList) do
                star:GetObject("TextName").text = info.Name
                star:GetObject("TextValue").text = info.Value
                break
            end
            
            star:GetObject("TextName").color = STAR_COLOR[IsActivate]
            star:GetObject("TextValue").color = STAR_COLOR[IsActivate]
            star:GetObject("TextPlus").color = STAR_COLOR[IsActivate]
            
            star:GetObject("PointLock").gameObject:SetActiveEx(IsLock)
            star:GetObject("PointPreview").gameObject:SetActiveEx(IsPreview)
            star:GetObject("PointActivate").gameObject:SetActiveEx(IsActivate)
        end
    end
    
    self.PanelEvolution:GetObject("TxtEvolution").text = string.format("%d/%d", nextClipCount - exMaxClipCount, maxClipCount - exMaxClipCount)
end

return XUiPanelQualityMain