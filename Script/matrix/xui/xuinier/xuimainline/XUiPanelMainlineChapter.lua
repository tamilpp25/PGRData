local XUiPanelMainlineChapter = XClass(nil, "XUiPanelMainlineChapter")
local XUiPanelChapterStage = require("XUi/XUiNieR/XUiMainLine/XUiPanelChapterStage")

local XUiGridNierStage = require("XUi/XUiNieR/XUiGridNierStage")
local TIME_TWEEN = 0.75
function XUiPanelMainlineChapter:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    
    XTool.InitUiObject(self)

    self.ChapeterList = {}
    for index = 1, 4 do
        self.ChapeterList[index] = self["PanelStage"..index] 
    end

end


function XUiPanelMainlineChapter:UpdateAllInfo()
    local chapterData = self.RootUi.CurChapterData
   
    local chapterIndex = chapterData:GetIndex()
    local PanelStage
    if not self.PanelChpterSatge then
    
        for index = 1, 4 do
            if chapterIndex == index then
                self.ChapeterList[index].gameObject:SetActiveEx(true)
                PanelStage = self.ChapeterList[index]
            else
                self.ChapeterList[index].gameObject:SetActiveEx(false)
            end
        end
        
        self.PanelChpterSatge = XUiPanelChapterStage.New(PanelStage, self.RootUi)
    end

    self.TxtChapter.text = chapterData:GetNieRChapterName()
    self.TxtNum.text= chapterData:GetNieRChapterPhaseStr()

    self.PanelChpterSatge:UpdateAllInfo(chapterData)
    
end

--废弃代码
-- function XUiPanelMainlineChapter:UpdateBossPercent(leftHp, maxHp)
--     if not self.LastLeftHp or self.LastLeftHp == 0 then
--         self.LastLeftHp = leftHp 
--         self.ImgJindu.fillAmount = (maxHp - leftHp) / maxHp
--         self.JinduLable.text = string.format("%d%s",math.floor( (maxHp - leftHp) / maxHp * 100), "%")
--     else
--         local changeHp = self.LastLeftHp - leftHp
--         if self.Tween then
--             XScheduleManager.UnSchedule(self.Tween)
--         end
--         self.Tween = XUiHelper.Tween(TIME_TWEEN, function(f)
--             if XTool.UObjIsNil(self.Transform) then
--                 return
--             end
--             local tmpChangeHp = math.floor(f * changeHp)
--             local tmpPercent = ( maxHp - self.LastLeftHp + tmpChangeHp ) / maxHp

--             self.ImgJindu.fillAmount = tmpPercent
--             self.JinduLable.text = string.format("%d%s",math.floor( tmpPercent * 100), "%")
        
--         end,function ()
--             if XTool.UObjIsNil(self.Transform) then
--                 return
--             end
--             self.LastLeftHp = leftHp 
--             self.ImgJindu.fillAmount = (maxHp - leftHp) / maxHp
--             self.JinduLable.text = string.format("%d%s",math.floor( (maxHp - leftHp) / maxHp * 100), "%")
--         end)
--     end
-- end

-- function XUiPanelMainlineChapter:StopTween()
--     if self.Tween then
--         XScheduleManager.UnSchedule(self.Tween)
--     end
-- end

return XUiPanelMainlineChapter