--招募界面：底下的成员列表控件中的格子
local XUiTheatreRecruitMemberGrid = XClass(nil, "XUiTheatreRecruitMemberGrid")

function XUiTheatreRecruitMemberGrid:Ctor()
    self.ElementImgIconList = {}
end

function XUiTheatreRecruitMemberGrid:Init(ui, rootUi)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)
    self:InitEffect()
    self.Disable.gameObject:SetActiveEx(true)
    self.Normal.gameObject:SetActiveEx(false)
    self.PanelSelected.gameObject:SetActiveEx(false)
end

function XUiTheatreRecruitMemberGrid:RefreshDatas(adventureRole, index)
    if not adventureRole then
        self.GameObject:SetActiveEx(false)
        return
    end
    
    local isUnLock = not XTool.IsTableEmpty(adventureRole)
    self.Normal.gameObject:SetActiveEx(isUnLock)
    self.Disable.gameObject:SetActiveEx(not isUnLock)

    if not isUnLock then
        return
    end
    
    local smallHeadIcon = adventureRole:GetSmallHeadIcon()
    self.RImgHeadIcon:SetRawImage(smallHeadIcon)

    local jobType = adventureRole:GetCareerType()
    self.RImgIconType:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(jobType))

    self.TxtName.text = adventureRole:GetRoleName()

    local elementList = adventureRole:GetElementList()
    local elementConfig
    local elementIconPath
    for i, elementId in ipairs(elementList) do
        local rImgIcon = self.ElementImgIconList[i]
        if not rImgIcon then
            rImgIcon = i == 1 and self.RImgIcon or XUiHelper.Instantiate(self.RImgIcon, self.PanelCharElement)
            self.ElementImgIconList[i] = rImgIcon
        end

        elementConfig = XCharacterConfigs.GetCharElement(elementId)
        elementIconPath = elementConfig.Icon2
        rImgIcon:SetRawImage(elementIconPath)
        rImgIcon.gameObject:SetActiveEx(true)
    end
    for i = #elementList + 1, #self.ElementImgIconList do
        self.ElementImgIconList[i].gameObject:SetActiveEx(false)
    end
end

function XUiTheatreRecruitMemberGrid:InitEffect()
    self.PanelEffectLvUp.gameObject:SetActiveEx(false)
end

function XUiTheatreRecruitMemberGrid:PlayEffect()
    self.PanelEffectLvUp.gameObject:SetActiveEx(false)
    self.PanelEffectLvUp.gameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(self.PanelEffectLvUp) then
            self.PanelEffectLvUp.gameObject:SetActiveEx(false)
        end
    end, XScheduleManager.SECOND)
end

function XUiTheatreRecruitMemberGrid:SetPanelSelectedActive(isActive)
    self.PanelSelected.gameObject:SetActiveEx(isActive)
end

return XUiTheatreRecruitMemberGrid