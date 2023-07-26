local UiButtonState = CS.UiButtonState
local EFFECT_COUNT = 3

--招募界面：招募角色的控件
local XUiTheatreRecruitRoleGrid = XClass(nil, "XUiTheatreRecruitRoleGrid")

function XUiTheatreRecruitRoleGrid:Ctor(ui, modelPanel, rootUi, gridIndex, closeCb)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)
    self.ModelPanel = modelPanel
    self.RootUi = rootUi
    self.GridIndex = gridIndex
    self.TxtName.text = ""
    self.ElementImgIconList = {}
    self.CloseCallback = closeCb

    self.BtnRecruit.CallBack = function() self:OnBtnRecruitClick() end
end

function XUiTheatreRecruitRoleGrid:Destroy()
    self.ModelPanel:RemoveRoleModelPool()
end

function XUiTheatreRecruitRoleGrid:RefreshDatas(adventureRole, playEffect)
    self.AdventureRole = adventureRole
    if not adventureRole then
        self.ImgEmpty.gameObject:SetActiveEx(true)
        self.PanelName.gameObject:SetActiveEx(false)
        self.BtnRecruit.gameObject:SetActiveEx(false)
        self.GridRecruited.gameObject:SetActiveEx(false)
        self.ModelPanel:HideRoleModel()
        return
    end
    self.ImgEmpty.gameObject:SetActiveEx(false)
    self.PanelName.gameObject:SetActiveEx(true)

    local adventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    local adventureChapter = adventureManager:GetCurrentChapter()

    self.TxtName.text = adventureRole:GetRoleName()

    local jobType = adventureRole:GetCareerType()
    self.RImgIconType:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(jobType))

    local elementList = adventureRole:GetElementList()
    local elementConfig
    local elementIconPath
    for i, elementId in ipairs(elementList) do
        local rImgIcon = self.ElementImgIconList[i]
        if not rImgIcon then
            rImgIcon = i == 1 and self.RImgIcon or XUiHelper.Instantiate(self.RImgIcon, self.PanelIconList)
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

    --是否已招募
    local isRecruit = adventureManager:GetRole(adventureRole:GetId()) ~= nil
    self.GridRecruited.gameObject:SetActiveEx(isRecruit)
    self.BtnRecruit.gameObject:SetActiveEx(not isRecruit)

    --是否可招募
    local isCanRecruit = adventureChapter:GetRecruitCount() > 0
    self.BtnRecruit:SetDisable(not isCanRecruit, isCanRecruit)

    self:UpdateRoleModel(adventureRole:GetCharacterId(), adventureRole:GetRawDataId(), playEffect)
end

--更新模型
function XUiTheatreRecruitRoleGrid:UpdateRoleModel(charId, robotId, playEffect)
    if not charId or not robotId then return end
    self.GameObject:SetActiveEx(true)
    if not self.ShowEffect then
        self.ShowEffect = {}
        for i = 1, EFFECT_COUNT do
            self.ShowEffect[i] = self.ModelPanel.Transform:Find("ImgEffectHuanren" .. i)
        end
    end

    local quality = XRobotManager.GetRobotCharacterQuality(robotId)
    for i, v in ipairs(self.ShowEffect) do
        v.gameObject:SetActiveEx(false)
        if (i == quality or (i == #self.ShowEffect and quality >= i)) and playEffect then
            v.gameObject:SetActiveEx(true)
            local effectObj = v
            XScheduleManager.ScheduleOnce(function()
                if not XTool.UObjIsNil(effectObj) then
                    effectObj.gameObject:SetActiveEx(false)
                end
            end, XScheduleManager.SECOND)
        end
    end
    
    self.ModelPanel:ShowRoleModel()
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    self.ModelPanel:UpdateRobotModel(robotId, 
        charId, 
        nil, 
        robotCfg and robotCfg.FashionId, 
        robotCfg and robotCfg.WeaponId)
end

function XUiTheatreRecruitRoleGrid:OnBtnRecruitClick()
    XLuaUiManager.Open("UiTheatreRoleDetails", self.AdventureRole, false, self.CloseCallback)
end

return XUiTheatreRecruitRoleGrid