package com.example.dayflow

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
import android.util.TypedValue
import androidx.annotation.FontRes
import androidx.core.content.res.ResourcesCompat
import kotlin.math.ceil
import kotlin.math.max

object WidgetTextBitmapFactory {
    fun renderSingleLine(
        context: Context,
        text: CharSequence,
        @FontRes fontRes: Int,
        textSizeSp: Float,
        color: Int,
        maxWidthPx: Int,
    ): Bitmap {
        val safeWidth = max(1, maxWidthPx)
        val paint = TextPaint(TextPaint.ANTI_ALIAS_FLAG).apply {
            isSubpixelText = true
            this.color = color
            textSize = TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_SP,
                textSizeSp,
                context.resources.displayMetrics
            )
            typeface = ResourcesCompat.getFont(context, fontRes)
        }

        val ellipsized = TextUtils.ellipsize(
            text,
            paint,
            safeWidth.toFloat(),
            TextUtils.TruncateAt.END
        )

        val desiredWidth = ceil(Layout.getDesiredWidth(ellipsized, paint).toDouble()).toInt()
            .coerceIn(1, safeWidth)

        val layout = StaticLayout.Builder
            .obtain(ellipsized, 0, ellipsized.length, paint, desiredWidth)
            .setAlignment(Layout.Alignment.ALIGN_NORMAL)
            .setIncludePad(false)
            .setMaxLines(1)
            .build()

        val bitmap = Bitmap.createBitmap(
            max(1, desiredWidth),
            max(1, layout.height),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(bitmap)
        layout.draw(canvas)
        return bitmap
    }
}
