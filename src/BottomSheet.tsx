import { requireNativeViewManager } from 'expo-modules-core';
import React from 'react'
import { LayoutChangeEvent, NativeSyntheticEvent, Platform, View, ViewStyle, findNodeHandle } from 'react-native'

import { BottomSheetProps, BottomSheetRef, BottomSheetNativeProps, SizeInfo } from './BottomSheet.types';
import { BottomSheetFooter } from './BottomSheetFooter';
import { BottomSheetGrabber } from './BottomSheetGrabber';

const ExpoBottomNativeView: React.ComponentType<BottomSheetNativeProps> =
  requireNativeViewManager('ExpoBottomSheet');

export default class BottomSheet extends React.PureComponent<BottomSheetProps> {
  /**
   * Map of sheet names against their handle.
   */
  private static readonly handles: { [name: string]: React.RefObject<BottomSheetRef> } = {}

  ref = React.createRef<BottomSheetRef>()

  state = {
    contentHeight: undefined,
    footerHeight: undefined,
    scrollableHandle: null,
  }

  private onSizeChange = (event: NativeSyntheticEvent<SizeInfo>): void => {
    this.props.onSizeChange?.(event.nativeEvent)
  }

  private onPresent = (event: NativeSyntheticEvent<SizeInfo>): void => {
    this.props.onPresent?.(event.nativeEvent)
  }

  private onDismiss = (): void => {
    this.props.onDismiss?.()
  }

  private onFooterLayout = (event: LayoutChangeEvent): void => {
    this.setState({
      footerHeight: event.nativeEvent.layout.height,
    })
  }

  private onContentLayout = (event: LayoutChangeEvent): void => {
    this.setState({
      contentHeight: event.nativeEvent.layout.height,
    })
  }

  async presentAsync(): Promise<void> {
    this.ref.current?.presentAsync()
  }

  private updateState(): void {
    const scrollableHandle = this.props.scrollRef?.current
      ? findNodeHandle(this.props.scrollRef.current)
      : null

    if (this.props.name) {
      BottomSheet.handles[this.props.name] = this.ref
    }

    this.setState({
      scrollableHandle,
    })
  }

  componentDidMount(): void {
    if (this.props.sizes && this.props.sizes.length > 3) {
      console.warn(
        'TrueSheet only supports a maximum of 3 sizes; collapsed, half-expanded and expanded. Check your `sizes` prop.'
      )
    }

    this.updateState()
  }

  componentDidUpdate(): void {
    this.updateState()
  }

  render(): React.ReactNode {
    const {
      sizes = ['medium', 'large'],
      backgroundColor = 'white',
      dismissible = true,
      grabber = true,
      dimmed = true,
      dimmedIndex,
      grabberProps,
      blurTint,
      cornerRadius,
      maxHeight,
      FooterComponent,
      style,
      contentContainerStyle,
      children,
      ...rest
    } = this.props

    return (
      <ExpoBottomNativeView
        ref={this.ref}
        style={$nativeSheet}
        scrollableHandle={this.state.scrollableHandle}
        sizes={sizes}
        blurTint={blurTint}
        cornerRadius={cornerRadius}
        contentHeight={this.state.contentHeight}
        footerHeight={this.state.footerHeight}
        grabber={grabber}
        dimmed={dimmed}
        dimmedIndex={dimmedIndex}
        dismissible={dismissible}
        maxHeight={maxHeight}
        onPresent={this.onPresent}
        onDismiss={this.onDismiss}
        onSizeChange={this.onSizeChange}
      >
        <View
          collapsable={false}
          style={[
            {
              overflow: Platform.select({ ios: undefined, android: 'hidden' }),
              borderTopLeftRadius: cornerRadius,
              borderTopRightRadius: cornerRadius,

              // Remove backgroundColor if `blurTint` is set on iOS
              backgroundColor: Platform.select({
                ios: blurTint ? undefined : backgroundColor,
                android: backgroundColor,
              }),
            },
            style,
          ]}
          {...rest}
        >
          <View collapsable={false} onLayout={this.onContentLayout} style={contentContainerStyle}>
            {children}
          </View>
          <View collapsable={false} onLayout={this.onFooterLayout}>
            <BottomSheetFooter Component={FooterComponent} />
          </View>
          {Platform.OS === 'android' && <BottomSheetGrabber visible={grabber} {...grabberProps} />}
        </View>
      </ExpoBottomNativeView>
    )
  }
}

const $nativeSheet: ViewStyle = {
  position: 'absolute',
  left: -9999,
  zIndex: -9999,
}
