local XUiGridTreasureGrade = require("XUi/XUiFubenMainLineChapter/XUiGridTreasureGrade")
local XUiGridNewCharTask=XClass(XUiGridTreasureGrade,'XUiGridNewCharTask')

function XUiGridNewCharTask:Ctor()
    self.GridDefaultTitle=self.TxtGrade.text
end

function XUiGridNewCharTask:Refresh()
    --隐藏和星星相关的UI
    self.ImgGradeStarActive.gameObject:SetActiveEx(false)
    self.ImgGradeStarUnactive.gameObject:SetActiveEx(false)
    self.TxtGradeStarNums.gameObject:SetActiveEx(false)
    self.PanelMultipleWeeksJindu.gameObject:SetActiveEx(true)
    self.ProgressBg.gameObject:SetActiveEx(false)
    --显示和进度条相关的UI
    self.ProgressBg.gameObject:SetActiveEx(true)
    self.TxtTaskNumQian.gameObject:SetActiveEx(true)
    self.TxtTaskDescribe.gameObject:SetActiveEx(true)
    --显示任务描述
    self.TxtGrade.text=self.TreasureCfg.Title
    self.TxtTaskDescribe.text = self.TreasureCfg.Description
    --根据类型设置进度
    local needStar=self.TreasureCfg.Type==XFubenNewCharConfig.TreasureType.RequireStar
    if needStar then --任务完成要求星星数
        local requireStars = self.TreasureCfg.RequireStar
        local curStars = self.CurStars > requireStars and requireStars or self.CurStars
        if XTool.IsNumberValid(requireStars) then
            self.ImgProgress.fillAmount = curStars / requireStars
        else
            self.ImgProgress.fillAmount=0
        end
        self.TxtTaskNumQian.text = CS.XTextManager.GetText("AlreadyobtainedCount", curStars, requireStars)

        --完成情况判定
        if requireStars > 0 and self.CurStars >= requireStars then
            local isGet= XDataCenter.FubenNewCharActivityManager.IsTreasureGet(self.TreasureCfg.TreasureId)
            if isGet then
                self:SetBtnAlreadyReceive()
            else
                self:SetBtnActive()
            end
        else
            self:SetBtnCannotReceive()
        end
    elseif self.TreasureCfg.Type==XFubenNewCharConfig.TreasureType.RequireStage then --任务完成要求通关指定关卡
        local ispass=XDataCenter.FubenManager.CheckStageIsPass(self.TreasureCfg.RequireStage)
        local completeCount=ispass and 1 or 0
        self.ImgProgress.fillAmount = completeCount
        self.TxtTaskNumQian.text = CS.XTextManager.GetText("AlreadyobtainedCount", completeCount, 1)
        
        --完成情况判定
        if ispass then
            local isGet= XDataCenter.FubenNewCharActivityManager.IsTreasureGet(self.TreasureCfg.TreasureId)
            if isGet then
                self:SetBtnAlreadyReceive()
            else
                self:SetBtnActive()
            end
        else
            self:SetBtnCannotReceive()
        end
    end
end

return XUiGridNewCharTask