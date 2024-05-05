import React from 'react'
import type { BottomSheetProps } from './BottomSheet.types'

interface BottomSheetFooterProps {
  Component?: BottomSheetProps['FooterComponent']
}

export const BottomSheetFooter = (props: BottomSheetFooterProps) => {
  const { Component } = props

  if (!Component) return null

  if (typeof Component !== 'function') {
    return Component
  }

  return <Component />
}
