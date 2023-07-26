local XUiGridFubenMainLineTheme = XClass(nil,"XUiGridFubenMainLineTheme")
---@param ui UnityEngine.GameObject
function XUiGridFubenMainLineTheme:Ctor(ui)
    self.GameObject = ui
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:RegisterButton()
end

function XUiGridFubenMainLineTheme:RegisterButton()
    self.BtnNormal.CallBack = function() 
        self:OnClickBtnTheme()
    end
    
    self.BtnSelect.CallBack = function() 
        self:OnClickBtnTheme()
    end
    
    self.BtnDisable.CallBack = function() 
        self:OnClickBtnTheme()
    end
end

function XUiGridFubenMainLineTheme:Refresh(chapterConfig,index)
    self.Index = index
    self.ChapterCfg = chapterConfig
    self.BtnNormal:SetNameByGroup(0, chapterConfig.ChapterName)
    self.BtnSelect:SetNameByGroup(0, chapterConfig.ChapterName)
    self.BtnDisable:SetNameByGroup(0, chapterConfig.ChapterName)
    self.BtnNormal:SetNameByGroup(1, chapterConfig.ChapterEn)
    self.BtnSelect:SetNameByGroup(1, chapterConfig.ChapterEn)
    self.BtnDisable:SetNameByGroup(1, chapterConfig.ChapterEn)
    if chapterConfig.OpenCondition > 0 then
        local isOpen = XConditionManager.CheckCondition(chapterConfig.OpenCondition)
        self.BtnNormal.gameObject:SetActiveEx(isOpen)
        self.BtnDisable.gameObject:SetActiveEx(not isOpen)
    end

end

function XUiGridFubenMainLineTheme:OnClickBtnTheme()
    if self.ChapterCfg.OpenCondition > 0 then
        local isOpen,desc = XConditionManager.CheckCondition(self.ChapterCfg.OpenCondition)
        if not isOpen then
            XUiManager.TipMsg(desc)
            return
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_MAINLINE_SELECT_CHAPTER,self.Index)
end


return XUiGridFubenMainLineTheme