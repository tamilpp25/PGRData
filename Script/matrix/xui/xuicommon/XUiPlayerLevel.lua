---通用等级处理接口，人物等级达到满级后将会显示荣耀的icon

XUiPlayerLevel = XUiPlayerLevel or {}

local Update = function(level, uiObject, desc)
    local txtLevel = uiObject:GetObject("TxtLevel")
    if not XTool.UObjIsNil(txtLevel) then
        if not desc or desc == "" then
            desc = level
        end
        txtLevel.text = desc
    end

    local gloryIcon = uiObject:GetObject("GloryIcon")
    if not XTool.UObjIsNil(gloryIcon) then
        gloryIcon.gameObject:SetActiveEx(XPlayer.CheckIsMaxLevel(level)) 
    end
end

--[[
    --@level: 只能传原始的等级(0~120)，不要传荣耀等级
    --@Object: UiObject组件，必须要有TxtLevel(等级)和GloryIcon(荣耀等级图标，level==120时候会显示)
    --@desc: TxtLevel的text显示文本，会替代level，可不传
]]
XUiPlayerLevel.UpdateLevel = function(level, Object, desc)
    if XTool.UObjIsNil(Object) then 
        return 
    end
    
    local uiObject = Object.transform:GetComponent("UiObject")
    if not uiObject then return end

    Update(level, uiObject, desc)
end
