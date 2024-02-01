--周年回顾界面
local XUiAnniversaryReview=XLuaUiManager.Register(XLuaUi,'UiAnniversaryReview')
local XUiGridAnniversaryReview=require('XUi/XUiAnniversary/XUiGridAnniversaryReview')
--region 生命周期
function XUiAnniversaryReview:OnAwake()
    self.DynamicTable=XDynamicTableNormal.New(self.List)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridAnniversaryReview,self)
    self.eventHandler=handler(self,self.OnEndDragEvent)
    self.DynamicTable.Imp:onEndDragEvent('+',self.eventHandler)
    self.PanelReport.gameObject:SetActiveEx(false)
    self.Panelshare.gameObject:SetActiveEx(false)
    self.ReportPanelCtrl=require('XUi/XUiAnniversary/XUiPanelAnniversaryReviewReport').New(self.PanelReport,self)
    self.SharePanelCtrl=require('XUi/XUiAnniversary/XUiPanelAnniversaryReviewShare').New(self.Panelshare,self)
    self.GridUi.gameObject:SetActiveEx(false)
    
    self.BtnBack.CallBack=function() self:Close() end
    self.BtnMainUi.CallBack=function() XLuaUiManager.RunMain() end
    self.latesetStandingPos=self.ScrollView.content.anchoredPosition.y
    self.moveDire=1
    self.moveLimit=CS.UnityEngine.Screen.height*CS.XGame.ClientConfig:GetFloat('AnniversaryReviewScrollLimitPercent')
    self.firstIn=true
    
    --禁用滚轮
    self.ScrollView.scrollSensitivity=0 
end

function XUiAnniversaryReview:OnStart()
    self.DynamicTable:SetTotalCount(self._Control:GetReviewPicturesCount())
    self.DynamicTable:ReloadDataSync()
    --初始化时手动修正一次位置：因为要用到Content长度，需要等待数据更新到下一帧
    XScheduleManager.ScheduleNextFrame(function()
        self:OnEndDragEvent()
    end)
    XDataCenter.ReviewActivityManager.SetOpenReview(function(isHitFace)
        self.IsHitFace = isHitFace
    end)
    
    self.alreadyLoadIndexes = {} --已经加载过一次的图片索引
end

function XUiAnniversaryReview:OnDestroy()
    self.DynamicTable.Imp:onEndDragEvent('-',self.eventHandler)
    XScheduleManager.UnSchedule(self.DOMoveId)
    if self.IsHitFace then
        XEventManager.DispatchEvent(XEventId.EVENT_REVIEW_ACTIVITY_HIT_FACE_END)
    end
end
--endregion

--region 事件处理
function XUiAnniversaryReview:OnDynamicTableEvent(event, index, grid)
    if event==DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then

    elseif event==DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index)
    end
end

function XUiAnniversaryReview:OnEndDragEvent()
    --位置修正
    if not self.isFixing and self.ScrollView then
        self.isFixing=true
        self.ScrollView:StopMovement()
        --计算出滑动方向
        local _moveDire=self.ScrollView.content.anchoredPosition.y-self.latesetStandingPos
        if _moveDire>self.moveLimit then
            self.moveDire=1
        elseif _moveDire<-self.moveLimit then
            self.moveDire=-1
        elseif self.firstIn then
            self.firstIn=false
        else
            self.moveDire=0
        end
        --找到距离当前锚点位置最近的修正点:规则：优先找滑动方向前面的最近点，其次找绝对值最近的点，都没有则返回原中心点
        local _anchoredPos=nil
        local posdiff=9999999
        local _absoluteposdiff=9999999 --绝对值上的最小距离
        local _absoluteNearestPos=nil --绝对值上最近的点
        local aimCenterIndex = -1
        local absoluteAimCenterIndex = -1
        for i, v in pairs(self.DynamicTable.ProxyMap or {}) do
            local results=v:GetAllAnchoredPoints()
            for index, data in pairs(results) do
                if data.hasResult then
                    local hasValue, screenCenterPoint = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.viewcenter, Vector2.zero, CS.XUiManager.Instance.UiCamera)
                    local aimPos=Vector3.up*screenCenterPoint.y-data.result

                    local tempDiff=self.moveDire*(aimPos.y-self.ScrollView.content.localPosition.y)
                    if tempDiff>0 and tempDiff<posdiff then
                        posdiff=tempDiff
                        _anchoredPos=aimPos
                        aimCenterIndex = data.index
                    end
                    if math.abs(tempDiff)<_absoluteposdiff then
                        _absoluteposdiff=math.abs(tempDiff)
                        _absoluteNearestPos=aimPos
                        absoluteAimCenterIndex = data.index
                    end
                end
            end

            --[[local hasResult,result=v:GetAnchoredCenterPoint()
            if hasResult then
                local hasValue, screenCenterPoint = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.viewcenter, Vector2.zero, CS.XUiManager.Instance.UiCamera)
                local aimPos=Vector3.up*screenCenterPoint.y-result

                local tempDiff=self.moveDire*(aimPos.y-self.ScrollView.content.localPosition.y)
                if tempDiff>=0 and tempDiff<posdiff then
                    posdiff=tempDiff
                    _anchoredPos=aimPos
                end
            end--]]
        end
        --插值
        XLuaUiManager.SetMask(true)
        self.DOMoveId = XUiHelper.DoMove(self.ScrollView.content, _anchoredPos or _absoluteNearestPos or Vector3(self.ScrollView.content.anchoredPosition.x,self.latesetStandingPos,0), XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            self.isFixing=false
            self.ScrollView:StopMovement()
            --记录静止后的坐标点，用于移动时判断移动方向            
            self.latesetStandingPos=self.ScrollView.content.anchoredPosition.y
            --播放动画
            local avaliableIndex=aimCenterIndex == -1 and absoluteAimCenterIndex or aimCenterIndex
            if avaliableIndex ~= -1 then
                if not XTool.IsTableEmpty(self.DynamicTable.ProxyMap) then
                    for i, aimCenterGrid in pairs(self.DynamicTable.ProxyMap) do
                        aimCenterGrid:RefreshWithAnimation(avaliableIndex)
                    end
                end
            end
            XLuaUiManager.SetMask(false)
        end)
        --[[self.ScrollView.content:DOAnchorPosY(_anchoredPos,CS.XGame.ClientConfig:GetFloat('AnniversaryReviewFixPosSpeed')):SetSpeedBased(true):OnComplete(function() 
            self.isFixing=false
            self.ScrollView:StopMovement()
        end)--]]
        
    end
end

function XUiAnniversaryReview:OpenReportPanel()
    self.ReportPanelCtrl:Open()
end

function XUiAnniversaryReview:OpenShare(closeCb)
    if not self.IsCreatePng then
        self.IsCreatePng=true
        local ctrl=XMVCA.XAnniversary:CreateAlbumControl()
        --增加数据显示UI控件
        if ctrl.CanvasContainer.PanelReport then
            ctrl.CanvasContainer.PanelReport.gameObject:SetActiveEx(false)
            ctrl.ReportUi=require('XUi/XUiAnniversary/XUiPanelAnniversaryReviewReport').New(ctrl.CanvasContainer.PanelReport,self)
        end
        if ctrl.CanvasContainer.RawImage then
            ctrl.CanvasContainer.RawImage.gameObject:SetActiveEx(false)
            ctrl.LongImageUi={}
            for i = 1, 100 do
                local panelUiGO=ctrl.LongImageContainer['PanelUI'..i]
                if panelUiGO then
                    panelUiGO.gameObject:SetActiveEx(false)
                    ctrl.LongImageUi['PanelUI'..i]=require('XUi/XUiAnniversary/XUiGridAnniversaryReviewData').New(panelUiGO,self)
                end
            end
        end
        --先生成短图，因此先显示短图UI
        ctrl.ReportUi:Open()
        ctrl:CreateShortAlbum(function(_shortT2d)
            --之后生成长图，因此关闭短图UI，打开长图UI
            ctrl.ReportUi:Close()
            ctrl.CanvasContainer.RawImage.gameObject:SetActiveEx(true)
            XScheduleManager.ScheduleNextFrame(function()
                ctrl:CreateLongAlbum(function(_longT2d)
                    self.SharePanelCtrl:Init(_longT2d,_shortT2d,ctrl)
                    self.SharePanelCtrl:SetCloseCb(closeCb)
                    self.SharePanelCtrl:Open()
                end)
            end)
        end)
    else
        self.SharePanelCtrl:SetCloseCb(closeCb)
        self.SharePanelCtrl:Open()
    end
    
end
--endregion

return XUiAnniversaryReview