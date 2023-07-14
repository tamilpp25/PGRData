
local XUiPanelPartnerShowMainSkillOption = require("XUi/XUiPartner/PartnerShow/XUiPanelPartnerShowMainSkillOption")
local XUiPanelPartnerShowMainSkillElement = require("XUi/XUiPartner/PartnerShow/XUiPanelPartnerShowMainSkillElement")
local XUiPanelPartnerShowMainSkill = XLuaUiManager.Register(XLuaUi, "UiPanelPartnerShowMainSkill")

local ChildPanelType = {
    SkillOption = 1,
    SkillElement = 2,
}

function XUiPanelPartnerShowMainSkill:OnAwake() 
    -- XPartnerMainSkillGroup
    self.Skill = nil
    -- XPartner
    self.Partner = nil
    -- XUiPanelPartnerShowMainSkillOption
    self.UiPanelPartnerShowMainSkillOption = nil -- XUiPanelPartnerShowMainSkillOption.New(self.PanelMainSkillOption)
    -- XUiPanelPartnerShowMainSkillElement
    self.XUiPanelPartnerShowMainSkillElement = nil
    -- ChildPanelType
    self.CurrentChildPanelType = nil
    -- 子面板信息配置
    self.ChillPanelInfoDic = {
        [ChildPanelType.SkillOption] = {
            instanceGo = self.PanelMainSkillOption,
            proxy = XUiPanelPartnerShowMainSkillOption,
            -- 代理参数
            proxyArgs = {
                "Skill",
                "Partner",
                function(skill)
                    self:ChangeChildPanelStatus(ChildPanelType.SkillElement, skill)
                end
            },
            animName = "QieHuan2",
        },
        [ChildPanelType.SkillElement] = {
            instanceGo = self.PanelElement,
            proxy = XUiPanelPartnerShowMainSkillElement,
            proxyArgs = {
                "Partner"
            },
            animName = "QieHuan1",
        },
    }
    self:RegisterUiEvents()
end

-- skill : XPartnerMainSkillGroup
-- partner : XPartner
function XUiPanelPartnerShowMainSkill:OnStart(skill, partner)
    self.Skill = skill
    self.Partner = partner
    -- 设置默认打开的子panel
    self:ChangeChildPanelStatus(ChildPanelType.SkillOption)
    -- 设置面板隐藏状态
    self.PanelMainSkillOption.gameObject:SetActiveEx(true)
    self.PanelElement.gameObject:SetActiveEx(false)
end

--########################## 私有方法 ##############################

function XUiPanelPartnerShowMainSkill:RegisterUiEvents()
    self.BtnTanchuangClose.CallBack = function() 
        if self.CurrentChildPanelType == ChildPanelType.SkillOption then
            self:Close()
        else
            self:ChangeChildPanelStatus(ChildPanelType.SkillOption)
        end
    end
end

function XUiPanelPartnerShowMainSkill:ChangeChildPanelStatus(panelType, ...)
    self.CurrentChildPanelType = panelType
    -- 显示/隐藏关联子面板
    for key, data in pairs(self.ChillPanelInfoDic) do
        data.instanceGo.gameObject:SetActiveEx(key == panelType)
    end
    local childPanelData = self.ChillPanelInfoDic[panelType]
    -- 加载panel proxy
    local instanceProxy = childPanelData.instanceProxy
    if instanceProxy == nil then
        instanceProxy = childPanelData.proxy.New(childPanelData.instanceGo)
        childPanelData.instanceProxy = instanceProxy
    end
    -- 加载proxy参数
    local proxyArgs = {}
    if childPanelData.proxyArgs then
        for _, argName in ipairs(childPanelData.proxyArgs) do
            if type(argName) == "string" then
                proxyArgs[#proxyArgs + 1] = self[argName]
            else
                proxyArgs[#proxyArgs + 1] = argName
            end
        end
    end
    proxyArgs = XTool.MergeArray(proxyArgs, {...})
    instanceProxy:SetData(table.unpack(proxyArgs))
    -- 播放ui进场动画
    if childPanelData.animName then
        XScheduleManager.ScheduleOnce(function()
            self:PlayAnimation(childPanelData.animName)
        end, 1)
    end
end