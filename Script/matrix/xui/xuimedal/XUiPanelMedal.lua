local XUiPanelMedal = XLuaUiManager.Register(XLuaUi, "UiPanelMedal")
local Dropdown = CS.UnityEngine.UI.Dropdown
local None = -1
function XUiPanelMedal:OnStart(viewlType)
    self.MedalView = XUiPanelMedalListView.New(self.PanelMedalScroll,XMedalConfigs.ViewType.Medal,self)
    self.CollectionView = XUiPanelMedalListView.New(self.PanelCollectionScroll,XMedalConfigs.ViewType.Collection,self)
    self.NameplateView = XUiPanelMedalListView.New(self.PanelNameplateScroll,XMedalConfigs.ViewType.Nameplate,self)

    self:InitDropdown()
    self:InitButtonGroup(viewlType)
    self:OnCheckBtnIsNotShow()

    XEventManager.AddEventListener(XEventId.EVENT_MEDAL_NOTIFY, self.ShowPanelMdeal, self)
    XEventManager.AddEventListener(XEventId.EVENT_SCORETITLE_CHANGE, self.ShowPanelMdeal, self)
    XEventManager.AddEventListener(XEventId.EVENT_MEDAL_REDPOINT_CHANGE, self.CheckRedPoint, self)
    XEventManager.AddEventListener(XEventId.EVENT_MEDAL_USE, self.ShowPanelMdeal, self)
    XEventManager.AddEventListener(XEventId.EVENT_NAMEPLATE_CHANGE, self.CheckRedPoint, self)
end


function XUiPanelMedal:OnEnable()
    if self.NeedPlayMedalListEnable then
        self:PlayAnimation("MedalListEnable")
    end
    self.NeedPlayMedalListEnable = true
    self:SetTypeTagShowRed()
    self:ShowPanelMdeal()
end

function XUiPanelMedal:OnDisable()
    self:ClearAllRedPoint()
    if self.NameplateIsSel then
        XDataCenter.MedalManager.SetNameplateRedPointDic()
    end 
end

function XUiPanelMedal:SetTypeTagShowRed()
    self.BtnXunzhang:ShowReddot(XDataCenter.MedalManager.CheckHaveNewMedalByType(XMedalConfigs.ViewType.Medal))
    self.BtnShoucangpin:ShowReddot(XDataCenter.MedalManager.CheckHaveNewMedalByType(XMedalConfigs.ViewType.Collection))--这里要改成类型检查
    self.BtnNameplate:ShowReddot(XDataCenter.MedalManager.CkeckHaveNewNameplate())
end

function XUiPanelMedal:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_MEDAL_NOTIFY, self.ShowPanelMdeal, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SCORETITLE_CHANGE, self.ShowPanelMdeal, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MEDAL_REDPOINT_CHANGE, self.CheckRedPoint, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MEDAL_USE, self.ShowPanelMdeal, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_NAMEPLATE_CHANGE, self.CheckRedPoint, self)
end

function XUiPanelMedal:OnCheckBtnIsNotShow()
    if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Medal) then
        self.BtnXunzhang.gameObject:SetActive(false)
    end
    if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Medal) then
        self.BtnShoucangpin.gameObject:SetActive(false)
    end
    if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Medal) then
        self.BtnNameplate.gameObject:SetActive(false)
    end
end

function XUiPanelMedal:InitDropdown()
    local screenTagList = XMedalConfigs.GetScoreScreenTagConfigs()

    self.BtnSort:ClearOptions()
    self.BtnSort.captionText.text = CS.XTextManager.GetText("ScreenAll")

    local firstOp = Dropdown.OptionData()
    firstOp.text = CS.XTextManager.GetText("ScreenAll")
    self.BtnSort.options:Add(firstOp)

    for _,v in pairs(screenTagList) do
        local op = Dropdown.OptionData()
        op.text = v.Name or ""
        self.BtnSort.options:Add(op)
    end
    self.CurScreenType = 0
    self.BtnSort.value = 0

    self.BtnSort.onValueChanged:AddListener(function()
            self.CurScreenType = self.BtnSort.value
            self.CollectionView:Refresh(self.BtnSort.value)
        end)
end

function XUiPanelMedal:InitButtonGroup(viewType)
    self.BtnXunzhang:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Medal))
    self.BtnShoucangpin:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Collection))
    self.BtnNameplate:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Nameplate))

    self.TypeBtn = {self.BtnXunzhang,self.BtnShoucangpin, self.BtnNameplate}
    self.CurType = None
    self.BtnGroup:Init(self.TypeBtn, function(index) self:SelectType(index) end)
    if viewType ~= None then
        self.BtnGroup:SelectIndex(viewType)
    end
end

function XUiPanelMedal:SelectType(index)
    local IsOpen = false
    if index == XMedalConfigs.ViewType.Medal then
        if  XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Medal) then
            IsOpen = true
            if not XDataCenter.MedalManager.CheckMedalStoryIsPlayed() then
                XDataCenter.MovieManager.PlayMovie(XDataCenter.MedalManager.MedalStroyId)
                XDataCenter.MedalManager.MarkMedalStory()
            end
            self:PlayAnimation("MedalListEnable")
        end
    elseif index == XMedalConfigs.ViewType.Collection then
        if  XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Collection) then
            IsOpen = true
            self:PlayAnimation("CollectionScrollQieHuan",function ()
                    XDataCenter.MedalManager.CheckQualityUpCollection()
                end)
        end
    elseif index == XMedalConfigs.ViewType.Nameplate then
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Nameplate) then
            IsOpen = true
            self:PlayAnimation("NameplateScrollEnable",function ()
                
            end)
        end
        self.NameplateIsSel = true
    end
    if IsOpen then
        self:ClearAllRedPoint(index)
        self.CurType = index
    else
        if self.CurType ~= None then
            local exType = self.CurType
            self.CurType = None
            self.BtnGroup:SelectIndex(exType)
        end
    end
    self.PanelNone.gameObject:SetActiveEx(self.CurType == None)
    self.EmptyText.text = CS.XTextManager.GetText("NotOpenCollection")

    if self.NameplateIsSel and self.CurType ~= XMedalConfigs.ViewType.Nameplate then
        XDataCenter.MedalManager.SetNameplateRedPointDic()
    end 

    self:ShowPanelMdeal()
end

function XUiPanelMedal:ClearAllRedPoint(index)
    local medaldatas = XDataCenter.MedalManager.GetMedals()
    local ScoreTitledatas = XDataCenter.MedalManager.GetScoreTitle()
    if index then
        if self.CurType ~= index then
            if self.CurType == XMedalConfigs.ViewType.Medal then
                self:DoClearRedPoint(medaldatas)
            elseif self.CurType == XMedalConfigs.ViewType.Collection then
                self:DoClearRedPoint(ScoreTitledatas)
            end
        end
    else
        self:DoClearRedPoint(medaldatas)
        self:DoClearRedPoint(ScoreTitledatas)
    end
end

function XUiPanelMedal:DoClearRedPoint(datas)
    for _,data in pairs(datas) do
        if not data.IsLock then
            XDataCenter.MedalManager.SetMedalForOld(data.Id,data.Type)
        end
    end
end

function XUiPanelMedal:SetMedalCount()
    if self.CurType ~= XMedalConfigs.ViewType.Medal then
        self.PanelAchvReach.gameObject:SetActiveEx(false)
        return
    end

    local maxCount = 0
    local nowCount = 0
    local medalsList = XDataCenter.MedalManager.GetMedals()
    for _, medal in pairs(medalsList or {}) do
        maxCount = maxCount + 1
        if not medal.IsLock then
            nowCount = nowCount + 1
        end
    end
    self.PanelAchvReach.gameObject:SetActiveEx(true)
    self.TxtAchvGetCount.text = string.format("%d%s%d", nowCount, "/", maxCount)
end

function XUiPanelMedal:RefreshMedalListView()
    self.MedalView.GameObject:SetActiveEx(false)
    self.CollectionView.GameObject:SetActiveEx(false)
    self.NameplateView.GameObject:SetActiveEx(false)

    if self.CurType == XMedalConfigs.ViewType.Medal then
        self.BtnSort.gameObject:SetActiveEx(false)
        self.MedalView.GameObject:SetActiveEx(true)
        self.MedalView:Refresh()
    elseif self.CurType == XMedalConfigs.ViewType.Collection then
        self.BtnSort.gameObject:SetActiveEx(true)
        self.CollectionView.GameObject:SetActiveEx(true)
        self.CollectionView:Refresh(self.CurScreenType)
    elseif self.CurType == XMedalConfigs.ViewType.Nameplate then
        self.BtnSort.gameObject:SetActiveEx(false)
        self.NameplateView.GameObject:SetActiveEx(true)
        self.NameplateView:Refresh()
    end
end

function XUiPanelMedal:ShowPanelMdeal()
    self:RefreshMedalListView()
    self:SetMedalCount()
end

function XUiPanelMedal:CheckRedPoint()
    self:RefreshMedalListView()
    self:SetTypeTagShowRed()
end