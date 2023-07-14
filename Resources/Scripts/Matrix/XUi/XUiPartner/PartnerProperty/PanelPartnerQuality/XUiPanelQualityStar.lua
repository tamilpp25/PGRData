local XUiPanelQualityStar = XClass(nil, "XUiPanelQualityStar")
local XUiGridCanEatPartner = require("XUi/XUiPartner/PartnerProperty/PanelPartnerQuality/XUiGridCanEatPartner")
local DOFillTime = 0.5
local STAR_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("0F70BCFF"),
    [false] = XUiHelper.Hexcolor2Color("6A6A6AFF"),
}

function XUiPanelQualityStar:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    self.SelectFoodDic = {}

    XTool.InitUiObject(self)
    self:InitPanelStarPoint()
    self:InitDynamicTable()
    self:InitPanelItems()
end

function XUiPanelQualityStar:InitPanelStarPoint()
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

function XUiPanelQualityStar:InitPanelItems()
    self.PanelItems:GetObject("BtnUpgrade").CallBack = function()
        self:OnBtnUpgradeClick()
    end
    
    self.PanelItems:GetObject("BtnSource").CallBack = function()
        self:OnBtnSourceClick()
    end
end

function XUiPanelQualityStar:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItems:GetObject("SffViewItem"))
    self.DynamicTable:SetProxy(XUiGridCanEatPartner)
    self.DynamicTable:SetDelegate(self)
    self.PanelItems:GetObject("GridEatItem").gameObject:SetActiveEx(false)
end

function XUiPanelQualityStar:OnBtnUpgradeClick()
    local list = {}
    local IsNotTraining = true
    for _,entity in pairs(self.SelectFoodDic)do
        table.insert(list, entity:GetId())
        if not entity:GetIsNotTraining() then
            IsNotTraining = false
        end
    end
    
    if not IsNotTraining then
        XDataCenter.PartnerManager.TipDialog(nil,function ()
                self:DoStarActivate(list)
            end,"PartnerIsTrainingHint")
    else
        self:DoStarActivate(list)
    end
end

function XUiPanelQualityStar:DoStarActivate(list)
    XDataCenter.PartnerManager.PartnerStarActivateRequest(self.Data:GetId(), list, function ()
            self.Base:UpdatePanel(self.Data)
        end)
end

function XUiPanelQualityStar:UpdatePanel(data)---刷新掉这个
    self.Data = data
    self.SelectFoodDic = {}
    self:UpdatePanelGrowUp()
    self:UpdatePanelStarPoint(false)
    self:SetupDynamicTable()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelQualityStar:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelQualityStar:UpdatePanelGrowUp()
    local nextQuality = self.Data:GetQuality() + 1
    local icon = XCharacterConfigs.GetCharacterQualityIcon(nextQuality)
    self.PanelGrowUp:GetObject("TxtSkill").text = self.Data:GetQualitySkillColumnCount()
    self.PanelGrowUp:GetObject("TxtSkillNext").text = self.Data:GetQualitySkillColumnCount(nextQuality)
    self.PanelGrowUp:GetObject("RawImageQuality"):SetRawImage(icon)
end

function XUiPanelQualityStar:UpdatePanelStarPoint(IsAnime)
    
    local addClipCount = 0
    for _,food in pairs(self.SelectFoodDic) do
        addClipCount = addClipCount + food:GetChipCurCount()
    end
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

function XUiPanelQualityStar:SetupDynamicTable()
    self.PageDatas = XDataCenter.PartnerManager.GetPartnerQualityUpDataList(self.Data:GetId())
    XPartnerSort.EatSortFunction(self.PageDatas)
    
    self.PanelItems:GetObject("PanelNone").gameObject:SetActiveEx(#self.PageDatas <= 0)
    self.PanelItems:GetObject("BtnSource").gameObject:SetActiveEx(#self.PageDatas <= 0)
    self.PanelItems:GetObject("BtnUpgrade").gameObject:SetActiveEx(#self.PageDatas > 0)
    
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiPanelQualityStar:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self)
    end
end

function XUiPanelQualityStar:SetSelectFood(entity, IsAdd)    
    if IsAdd then
        if self.IsSelectClipFull then
            XUiManager.TipText("PartnerAllStarCanActivate")
            return
        end
        
        if not self.SelectFoodDic[entity:GetId()] then
            self.SelectFoodDic[entity:GetId()] = entity
        end
    else
        if self.SelectFoodDic[entity:GetId()] then
            self.SelectFoodDic[entity:GetId()] = nil
        end
    end
    self:UpdatePanelStarPoint(true)
end

function XUiPanelQualityStar:CheckIsSelectFood(id)
    return self.SelectFoodDic[id] and true or false
end

function XUiPanelQualityStar:OnBtnSourceClick()
    local skipIds = self.Data:GetClipSkipIdList()
    XLuaUiManager.Open("UiPartnerStrengthenSkip", skipIds)
end

return XUiPanelQualityStar