local XUiFightNieRTips = XLuaUiManager.Register(XLuaUi, "UiFightNieRTips")

local ANI_TIME = 3000
function XUiFightNieRTips:OnAwake()
    self.PanelCondition.gameObject:SetActiveEx(true)
    self.PanelCondition2.gameObject:SetActiveEx(true)
    self.PanelConditionCa.alpha = 0
    self.PanelCondition2Ca.alpha = 0
end


function XUiFightNieRTips:OnStart(lastPlayer, nowPlayer)
    
    self:PlayAnimation(lastPlayer, nowPlayer)
end

function XUiFightNieRTips:OnDestroy()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
    if self.Timer1 then
        XScheduleManager.UnSchedule(self.Timer1)
        self.Timer1 = nil
    end
end

function XUiFightNieRTips:PlayAnimation(lastPlayer, nowPlayer)
    self.TitleCondition.text  = CS.XTextManager.GetText("NieREasterEggReviveStr", lastPlayer or "")
    self.TitleCondition2.text  = CS.XTextManager.GetText("NieREasterEggReviveStr", nowPlayer or "")
    local timeTween = 0.1
    local Vector1 = CS.UnityEngine.Vector3(0, 189, 0)
    local Vector2 = CS.UnityEngine.Vector3(0, 125, 0)
    local Vector3 = CS.UnityEngine.Vector3(0, 253 + 15, 0)
    if not lastPlayer then 
        self.PanelCondition2Ca.alpha = 1
        self.PanelConditionRe.anchoredPosition3D = Vector2
        XUiHelper.DoUiMove(self.PanelCondition2Re, Vector1, timeTween,  XUiHelper.EaseType.Linear,function()

        end)
        self.Timer = XScheduleManager.ScheduleOnce(function()
            if not self.GameObject or  not self.GameObject:Exist() then return end
            self.Timer = nil
            self:Close()
        end, ANI_TIME)
    else
        self.PanelConditionRe.anchoredPosition3D = Vector2
        self.PanelCondition2Re.anchoredPosition3D = Vector2
        self.PanelConditionCa.alpha = 1
        XUiHelper.DoUiMove(self.PanelConditionRe, Vector1, timeTween,  XUiHelper.EaseType.Linear,function()
                
            -- XUiHelper.DoUiMove(self.PanelCondition2Re, Vector1, timeTween,  XUiHelper.EaseType.Linear,function()
            
            -- end)
        end)
        self.Timer = XScheduleManager.ScheduleOnce(function()
            if not self.GameObject or  not self.GameObject:Exist() then return end
            XUiHelper.DoUiMove(self.PanelCondition2Re, Vector1, timeTween,  XUiHelper.EaseType.Linear,function()
                
                -- XUiHelper.DoUiMove(self.PanelCondition2Re, Vector1, timeTween,  XUiHelper.EaseType.Linear,function()
                
                -- end)
            end)
            self.Timer = nil
            self.PanelConditionRe.anchoredPosition3D = Vector3
            self.PanelCondition2Ca.alpha = 1
            self.Timer1 = XScheduleManager.ScheduleOnce(function()
                if not self.GameObject or  not self.GameObject:Exist() then return end
                self.Timer1 = nil
                self:Close()
                -- self.Timer2 = XScheduleManager.ScheduleOnce(function()
                --     self:Close()
                -- end, ANI_TIME)
            end, ANI_TIME)

            
        end, ANI_TIME)
        
    end
end