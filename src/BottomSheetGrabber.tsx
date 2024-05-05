import React from 'react'
import { View, type ViewStyle } from 'react-native'

import { BottomSheetGrabberProps } from './BottomSheet.types'

const GRABBER_DEFAULT_HEIGHT = 4
const GRABBER_DEFAULT_WIDTH = 32

// M3 spec: #49454F 0.4 alpha
const GRABBER_DEFAULT_COLOR = 'rgba(73,69,79,0.4)'

/**
 * Grabber component.
 * Used by default for Android but feel free to re-use.
 */
export const BottomSheetGrabber = (props: BottomSheetGrabberProps) => {
  const {
    visible = true,
    color = GRABBER_DEFAULT_COLOR,
    width = GRABBER_DEFAULT_WIDTH,
    height = GRABBER_DEFAULT_HEIGHT,
    topOffset = 0,
    style,
  } = props

  if (!visible) return null

  return (
    <View style={[$wrapper, style, { height: GRABBER_DEFAULT_HEIGHT * 4, top: topOffset }]}>
      <View style={[$grabber, { height, width, backgroundColor: color }]} />
    </View>
  )
}

const $wrapper: ViewStyle = {
  position: 'absolute',
  alignSelf: 'center',
  paddingHorizontal: 12,
  alignItems: 'center',
  justifyContent: 'center',
  zIndex: 9999,
}

const $grabber: ViewStyle = {
  borderRadius: GRABBER_DEFAULT_HEIGHT / 2,
}
