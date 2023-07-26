local XUiPanelSkillMain = XClass(nil, "XUiPanelSkillMain")

function XUiPanelSkillMain:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    XTool.InitUiObject(self)
    self.PassiveSkillGoList = nil               -- 被动技能预制体列表
    self:InitPassiveSkill()
    self:SetButtonCallBack()
end

function XUiPanelSkillMain:InitPassiveSkill()
    self.PassiveSkillGoList = {
        self.PanelCircle:GetObject("PassiveSkillPos1"),
        self.PanelCircle:GetObject("PassiveSkillPos2"),
        self.PanelCircle:GetObject("PassiveSkillPos3"),
        self.PanelCircle:GetObject("PassiveSkillPos4"),
        self.PanelCircle:GetObject("PassiveSkillPos5"),
    }
end

function XUiPanelSkillMain:SetButtonCallBack()

    self.PanelMainSkill:GetObject("BtnMainSkill").CallBack = function()
        local selectIndex = 1
        self.Base:SetSkillInfoState(selectIndex)
        self.Base:ShowPanel()
    end

    for i, passiveSkillGo in ipairs(self.PassiveSkillGoList) do
        local selectIndex = i + 1
        passiveSkillGo:GetObject("BtnSkill").CallBack = function()
            self.Base:SetSkillInfoState(selectIndex)
            self.Base:ShowPanel()
        end
    end
end

function XUiPanelSkillMain:UpdatePanel(data)
    self.Data = data
    self.GameObject:SetActiveEx(true)

    self:UpdateMainSkill()
    self:UpdatePassiveSkill()
end

function XUiPanelSkillMain:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelSkillMain:UpdateMainSkill()
    local mainSkillGroupList = self.Data:GetMainSkillGroupList()
    for _, entity in pairs(mainSkillGroupList or {}) do--主技能共享技能等级，此处只显示装备中的主技能
        if entity:GetIsCarry() then
            self.PanelMainSkill:GetObject("RImgSkillIcon"):SetRawImage(entity:GetSkillIcon())
            self.PanelMainSkill:GetObject("TxtName").text = entity:GetSkillName()
            self.PanelMainSkill:GetObject("TxtLvNumber").text = entity:GetLevelStr()
            break
        end
    end
end

function XUiPanelSkillMain:UpdatePassiveSkill()
    local passiveSkillEntityDic = self.Data:GetPassiveSkillGroupEntityDic()
    local posindex = 1
    for _, entity in pairs(passiveSkillEntityDic or {}) do
        local skillGo = self.PassiveSkillGoList[posindex]
        if skillGo then
            skillGo:GetObject("RImgSkillIcon"):SetRawImage(entity:GetSkillIcon())
            skillGo:GetObject("TxtLvNumber").text = entity:GetLevelStr()
            skillGo.gameObject:SetActiveEx(true)
            posindex = posindex + 1
        end
    end

    for index = posindex, #self.PassiveSkillGoList do
        self.PassiveSkillGoList[index].gameObject:SetActiveEx(false)
    end
end

function XUiPanelSkillMain:PlayEnableAnime()
    XScheduleManager.ScheduleOnce(function()
        local timeline=self.Base.Animation:GetObject("PanelSkillMainEnable")
        --仅当该组件在场景中处于活跃状态且控件开启下才播放动画
        if not XTool.UObjIsNil(timeline.gameObject) and timeline.gameObject.activeInHierarchy==true then
            timeline:PlayTimelineAnimation()
        end
    end, 1)
end

return XUiPanelSkillMain