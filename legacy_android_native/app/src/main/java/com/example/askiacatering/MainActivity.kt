package com.example.askiacatering

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.askiacatering.ui.theme.AskiaCateringTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            AskiaCateringTheme {
                CateringApp()
            }
        }
    }
}

private enum class UserRole(val title: String, val subtitle: String) {
    BUYER("Pembeli", "Cari katering, jelajah wilayah, lalu pesan."),
    SELLER("Penjual", "Kelola paket, area layanan, dan pesanan."),
    ADMIN("Admin", "Pantau partner, performa wilayah, dan operasional.")
}

private enum class DiscoverMode(val title: String) {
    LIST("Daftar"),
    MAP("Peta Wilayah")
}

private data class MenuPackage(
    val title: String,
    val price: String,
    val description: String,
    val minimumOrder: String
)

private data class CateringVendor(
    val id: Int,
    val name: String,
    val region: String,
    val rating: Double,
    val reviewCount: Int,
    val eta: String,
    val minOrder: String,
    val priceRange: String,
    val shortDescription: String,
    val tags: List<String>,
    val featuredMenus: List<String>,
    val packages: List<MenuPackage>
)

private data class RegionStat(
    val name: String,
    val activeVendorCount: Int,
    val avgEta: String,
    val accent: Color
)

private val regions = listOf(
    RegionStat("Jakarta Selatan", 18, "25 menit", Color(0xFFE76F51)),
    RegionStat("Jakarta Barat", 12, "32 menit", Color(0xFFF4A261)),
    RegionStat("Jakarta Timur", 16, "28 menit", Color(0xFF2A9D8F)),
    RegionStat("Jakarta Pusat", 9, "20 menit", Color(0xFF264653)),
    RegionStat("Bandung", 14, "35 menit", Color(0xFF457B9D)),
    RegionStat("Tangerang", 11, "30 menit", Color(0xFF8AB17D))
)

private val vendors = listOf(
    CateringVendor(
        id = 1,
        name = "Dapur Nusantara Premium",
        region = "Jakarta Selatan",
        rating = 4.9,
        reviewCount = 321,
        eta = "25 - 35 menit",
        minOrder = "Min. 20 pax",
        priceRange = "Rp28rb - Rp55rb/pax",
        shortDescription = "Spesialis menu rumahan premium untuk kantor, arisan, dan event keluarga.",
        tags = listOf("Best Seller", "Higienis", "Bisa Langganan"),
        featuredMenus = listOf("Nasi Liwet", "Ayam Bakar Madu", "Tumis Buncis", "Puding Regal"),
        packages = listOf(
            MenuPackage("Paket Hemat Kantoran", "Rp28.000", "Nasi, ayam serundeng, sayur, sambal, air mineral.", "20 pax"),
            MenuPackage("Paket Premium Meeting", "Rp42.000", "Nasi liwet, ayam bakar madu, tumis sayur, buah, dessert.", "30 pax"),
            MenuPackage("Paket Buffet Keluarga", "Rp55.000", "Buffet lengkap dengan snack box pembuka.", "50 pax")
        )
    ),
    CateringVendor(
        id = 2,
        name = "Saji Sehat Ibu Rani",
        region = "Jakarta Barat",
        rating = 4.7,
        reviewCount = 184,
        eta = "30 - 40 menit",
        minOrder = "Min. 15 pax",
        priceRange = "Rp25rb - Rp39rb/pax",
        shortDescription = "Pilihan katering sehat rendah minyak untuk makan harian dan kebutuhan kantor.",
        tags = listOf("Healthy", "Halal", "Menu Diet"),
        featuredMenus = listOf("Nasi Merah", "Dori Lemon", "Capcay Sehat", "Salad Buah"),
        packages = listOf(
            MenuPackage("Paket Lunch Fit", "Rp25.000", "Nasi merah, lauk panggang, sayur kukus, infused water.", "15 pax"),
            MenuPackage("Paket Corporate Healthy", "Rp34.000", "Menu rendah minyak lengkap dengan buah potong.", "25 pax"),
            MenuPackage("Paket Diet Mingguan", "Rp39.000", "Rotasi menu sehat 5 hari.", "20 pax")
        )
    ),
    CateringVendor(
        id = 3,
        name = "Selera Priangan",
        region = "Bandung",
        rating = 4.8,
        reviewCount = 267,
        eta = "35 - 45 menit",
        minOrder = "Min. 25 pax",
        priceRange = "Rp27rb - Rp48rb/pax",
        shortDescription = "Masakan Sunda yang kuat rasa, cocok untuk gathering dan acara komunitas.",
        tags = listOf("Masakan Sunda", "Buffet", "Acara Besar"),
        featuredMenus = listOf("Nasi Timbel", "Ayam Goreng Lengkuas", "Karedok", "Es Cendol"),
        packages = listOf(
            MenuPackage("Paket Syukuran", "Rp27.000", "Menu Sunda basic untuk kumpul keluarga.", "25 pax"),
            MenuPackage("Paket Gathering", "Rp38.000", "Lauk lengkap plus snack tradisional.", "40 pax"),
            MenuPackage("Paket Prasmanan Event", "Rp48.000", "Prasmanan untuk event kantor dan seminar.", "75 pax")
        )
    ),
    CateringVendor(
        id = 4,
        name = "Kantin Kota Tengah",
        region = "Jakarta Pusat",
        rating = 4.6,
        reviewCount = 142,
        eta = "18 - 25 menit",
        minOrder = "Min. 10 pax",
        priceRange = "Rp22rb - Rp36rb/pax",
        shortDescription = "Cepat, praktis, dan cocok untuk rapat mendadak atau pesanan kantor harian.",
        tags = listOf("Cepat Sampai", "Meeting Box", "Favorite Kantor"),
        featuredMenus = listOf("Nasi Box Ayam Rica", "Beef Teriyaki", "Mie Goreng Jawa"),
        packages = listOf(
            MenuPackage("Paket Meeting Box", "Rp22.000", "Nasi box siap kirim untuk rapat mendadak.", "10 pax"),
            MenuPackage("Paket Executive Box", "Rp31.000", "Menu lebih premium dengan dessert.", "20 pax"),
            MenuPackage("Paket Harian Kantor", "Rp36.000", "Berlangganan makan siang mingguan.", "30 pax")
        )
    ),
    CateringVendor(
        id = 5,
        name = "Dapur Bunda Timur",
        region = "Jakarta Timur",
        rating = 4.8,
        reviewCount = 198,
        eta = "22 - 30 menit",
        minOrder = "Min. 20 pax",
        priceRange = "Rp24rb - Rp44rb/pax",
        shortDescription = "Rasa rumahan yang konsisten untuk acara sekolah, pengajian, dan kantor.",
        tags = listOf("Rumahan", "Favorit Sekolah", "Snack Box"),
        featuredMenus = listOf("Semur Daging", "Ayam Kecap", "Perkedel", "Lemper"),
        packages = listOf(
            MenuPackage("Paket Sekolah", "Rp24.000", "Praktis dan disukai anak-anak.", "20 pax"),
            MenuPackage("Paket Arisan", "Rp33.000", "Menu rumahan lengkap dengan snack.", "25 pax"),
            MenuPackage("Paket Pengajian", "Rp44.000", "Lauk lengkap, buah, dan teh manis.", "40 pax")
        )
    ),
    CateringVendor(
        id = 6,
        name = "Tangerang Feast House",
        region = "Tangerang",
        rating = 4.5,
        reviewCount = 108,
        eta = "28 - 38 menit",
        minOrder = "Min. 30 pax",
        priceRange = "Rp26rb - Rp47rb/pax",
        shortDescription = "Pilihan menu modern untuk event startup, workshop, dan private lunch.",
        tags = listOf("Modern Menu", "Event", "Custom Branding"),
        featuredMenus = listOf("Chicken Mentai", "Spaghetti Aglio", "Caesar Salad", "Brownies Cup"),
        packages = listOf(
            MenuPackage("Paket Workshop", "Rp26.000", "Makan siang simple dengan snack.", "30 pax"),
            MenuPackage("Paket Startup Lunch", "Rp37.000", "Menu fusion untuk meeting tim.", "35 pax"),
            MenuPackage("Paket Launching", "Rp47.000", "Buffet modern dengan plating premium.", "60 pax")
        )
    )
)

@Composable
private fun CateringApp() {
    var activeRole by rememberSaveable { mutableStateOf(UserRole.BUYER) }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        containerColor = MaterialTheme.colorScheme.background
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            MaterialTheme.colorScheme.background,
                            MaterialTheme.colorScheme.surface,
                            MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f)
                        )
                    )
                )
                .padding(innerPadding)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp)
            ) {
                Spacer(modifier = Modifier.height(12.dp))
                HeaderSection(activeRole = activeRole)
                Spacer(modifier = Modifier.height(20.dp))
                RoleSwitcher(activeRole = activeRole, onRoleSelected = { activeRole = it })
                Spacer(modifier = Modifier.height(20.dp))
                AnimatedContent(targetState = activeRole, label = "role-content") { role ->
                    when (role) {
                        UserRole.BUYER -> BuyerDashboard()
                        UserRole.SELLER -> SellerDashboard()
                        UserRole.ADMIN -> AdminDashboard()
                    }
                }
            }
        }
    }
}

@Composable
private fun HeaderSection(activeRole: UserRole) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(28.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 6.dp,
        shadowElevation = 10.dp
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    brush = Brush.linearGradient(
                        colors = listOf(
                            MaterialTheme.colorScheme.primary.copy(alpha = 0.18f),
                            MaterialTheme.colorScheme.tertiary.copy(alpha = 0.12f),
                            MaterialTheme.colorScheme.surface
                        )
                    )
                )
                .padding(20.dp)
        ) {
            Text(
                text = "Askia Catering",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Pusat pemesanan katering online dengan pencarian cepat, jelajah wilayah berbasis peta, dan dashboard terpisah untuk pembeli, penjual, dan admin.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(16.dp))
            Surface(
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                shape = RoundedCornerShape(18.dp)
            ) {
                Text(
                    text = activeRole.subtitle,
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}

@Composable
private fun RoleSwitcher(
    activeRole: UserRole,
    onRoleSelected: (UserRole) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(22.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.8f))
            .padding(6.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        UserRole.entries.forEach { role ->
            val isSelected = role == activeRole
            val container by animateColorAsState(
                targetValue = if (isSelected) MaterialTheme.colorScheme.primary else Color.Transparent,
                label = "role-color"
            )
            val weight by animateDpAsState(
                targetValue = if (isSelected) 2.dp else 0.dp,
                animationSpec = spring(stiffness = Spring.StiffnessLow),
                label = "role-shadow"
            )
            Surface(
                modifier = Modifier
                    .weight(1f)
                    .clickable { onRoleSelected(role) },
                shape = RoundedCornerShape(18.dp),
                color = container,
                shadowElevation = weight
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 14.dp, horizontal = 10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = role.title,
                        style = MaterialTheme.typography.titleMedium,
                        color = if (isSelected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = role.subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = if (isSelected) MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.85f) else MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

@Composable
private fun BuyerDashboard() {
    var query by rememberSaveable { mutableStateOf("") }
    var activeRegion by rememberSaveable { mutableStateOf("Semua Wilayah") }
    var discoverMode by rememberSaveable { mutableStateOf(DiscoverMode.LIST) }
    var selectedVendorId by rememberSaveable { mutableIntStateOf(vendors.first().id) }
    var cartCount by rememberSaveable { mutableIntStateOf(0) }

    val filteredVendors = vendors.filter { vendor ->
        val matchesQuery = query.isBlank() ||
            vendor.name.contains(query, ignoreCase = true) ||
            vendor.shortDescription.contains(query, ignoreCase = true) ||
            vendor.featuredMenus.any { it.contains(query, ignoreCase = true) }
        val matchesRegion = activeRegion == "Semua Wilayah" || vendor.region == activeRegion
        matchesQuery && matchesRegion
    }

    val selectedVendor = filteredVendors.firstOrNull { it.id == selectedVendorId }
        ?: filteredVendors.firstOrNull()
        ?: vendors.first()

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            HeroBuyerCard(cartCount = cartCount)
        }
        item {
            OutlinedTextField(
                value = query,
                onValueChange = { query = it },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp),
                label = { Text("Cari katering, menu, atau jenis acara") },
                placeholder = { Text("Contoh: buffet, sehat, nasi box") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Words)
            )
        }
        item {
            DiscoverModeSwitcher(mode = discoverMode, onModeSelected = { discoverMode = it })
        }
        item {
            RegionFilterRow(
                activeRegion = activeRegion,
                onRegionSelected = { region ->
                    activeRegion = region
                    selectedVendorId = filteredVendors.firstOrNull()?.id ?: vendors.first().id
                }
            )
        }
        item {
            if (discoverMode == DiscoverMode.MAP) {
                RegionMapSection(
                    activeRegion = activeRegion,
                    onRegionSelected = { region ->
                        activeRegion = region
                        selectedVendorId = vendors.firstOrNull { it.region == region }?.id ?: selectedVendorId
                    }
                )
            } else {
                SectionTitle(
                    title = "Katering Terdekat & Populer",
                    subtitle = "${filteredVendors.size} mitra cocok dengan pencarianmu."
                )
            }
        }
        if (discoverMode == DiscoverMode.LIST) {
            items(filteredVendors, key = { it.id }) { vendor ->
                VendorCard(
                    vendor = vendor,
                    selected = vendor.id == selectedVendor.id,
                    onClick = { selectedVendorId = vendor.id }
                )
            }
        }
        item {
            VendorDetailCard(
                vendor = selectedVendor,
                onAddPackage = { cartCount += 1 }
            )
        }
    }
}

@Composable
private fun HeroBuyerCard(cartCount: Int) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(30.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 8.dp
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    brush = Brush.linearGradient(
                        colors = listOf(
                            MaterialTheme.colorScheme.primary.copy(alpha = 0.95f),
                            MaterialTheme.colorScheme.tertiary.copy(alpha = 0.86f)
                        ),
                        start = Offset.Zero,
                        end = Offset(1200f, 1200f)
                    )
                )
                .padding(22.dp)
        ) {
            Text(
                text = "Pesan katering tanpa ribet",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Cari lewat daftar atau jelajahi wilayah di peta, lalu masuk ke katering yang paling cocok untuk acara kamu.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.92f)
            )
            Spacer(modifier = Modifier.height(18.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                MetricPill(title = "Mitra Aktif", value = "80+")
                MetricPill(title = "Wilayah", value = "6 Kota")
                MetricPill(title = "Keranjang", value = cartCount.toString())
            }
        }
    }
}

@Composable
private fun MetricPill(title: String, value: String) {
    Surface(
        modifier = Modifier.wrapContentHeight(),
        shape = RoundedCornerShape(18.dp),
        color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.14f)
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp)
        ) {
            Text(
                text = value,
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onPrimary
            )
            Text(
                text = title,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.84f)
            )
        }
    }
}

@Composable
private fun DiscoverModeSwitcher(
    mode: DiscoverMode,
    onModeSelected: (DiscoverMode) -> Unit
) {
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        DiscoverMode.entries.forEach { item ->
            val selected = item == mode
            Surface(
                modifier = Modifier.clickable { onModeSelected(item) },
                shape = RoundedCornerShape(20.dp),
                color = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surface,
                tonalElevation = if (selected) 4.dp else 0.dp,
                border = BorderStroke(
                    1.dp,
                    if (selected) Color.Transparent else MaterialTheme.colorScheme.outline.copy(alpha = 0.3f)
                )
            ) {
                Text(
                    text = item.title,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                    style = MaterialTheme.typography.labelLarge,
                    color = if (selected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface
                )
            }
        }
    }
}

@Composable
private fun RegionFilterRow(
    activeRegion: String,
    onRegionSelected: (String) -> Unit
) {
    val regionsWithAll = listOf("Semua Wilayah") + regions.map { it.name }
    Row(
        modifier = Modifier.horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        regionsWithAll.forEach { region ->
            val selected = region == activeRegion
            Surface(
                modifier = Modifier.clickable { onRegionSelected(region) },
                shape = RoundedCornerShape(18.dp),
                color = if (selected) MaterialTheme.colorScheme.secondaryContainer else MaterialTheme.colorScheme.surface,
                border = BorderStroke(
                    1.dp,
                    if (selected) MaterialTheme.colorScheme.secondary else MaterialTheme.colorScheme.outline.copy(alpha = 0.25f)
                )
            ) {
                Text(
                    text = region,
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp),
                    style = MaterialTheme.typography.labelLarge,
                    color = if (selected) MaterialTheme.colorScheme.onSecondaryContainer else MaterialTheme.colorScheme.onSurface
                )
            }
        }
    }
}

@Composable
private fun RegionMapSection(
    activeRegion: String,
    onRegionSelected: (String) -> Unit
) {
    val primaryTint = MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)
    val outlineTint = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f)
    val secondaryTint = MaterialTheme.colorScheme.secondary.copy(alpha = 0.18f)
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(28.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
    ) {
        Column(modifier = Modifier.padding(18.dp)) {
            SectionTitle(
                title = "Jelajahi via Peta Wilayah",
                subtitle = "Ketuk area untuk melihat katering yang aktif di region tersebut."
            )
            Spacer(modifier = Modifier.height(16.dp))
            Canvas(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(140.dp)
            ) {
                val dash = PathEffect.dashPathEffect(floatArrayOf(18f, 14f), 0f)
                drawRoundRect(
                    color = primaryTint,
                    topLeft = Offset(0f, 0f),
                    size = Size(size.width, size.height),
                    cornerRadius = CornerRadius(40f, 40f)
                )
                repeat(4) { step ->
                    val y = size.height / 4f * (step + 1)
                    drawLine(
                        color = outlineTint,
                        start = Offset(0f, y),
                        end = Offset(size.width, y),
                        strokeWidth = 3f,
                        pathEffect = dash
                    )
                }
                repeat(3) { step ->
                    val x = size.width / 3f * (step + 1)
                    drawLine(
                        color = outlineTint,
                        start = Offset(x, 0f),
                        end = Offset(x, size.height),
                        strokeWidth = 3f,
                        pathEffect = dash
                    )
                }
                drawCircle(
                    color = secondaryTint,
                    radius = 26.dp.toPx(),
                    center = Offset(size.width * 0.72f, size.height * 0.42f),
                    style = Stroke(width = 8f)
                )
            }
            Spacer(modifier = Modifier.height(16.dp))
            LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                items(regions) { region ->
                    val selected = activeRegion == region.name
                    RegionMapCard(
                        region = region,
                        selected = selected,
                        onClick = { onRegionSelected(region.name) }
                    )
                }
            }
        }
    }
}

@Composable
private fun RegionMapCard(
    region: RegionStat,
    selected: Boolean,
    onClick: () -> Unit
) {
    val background = if (selected) region.accent.copy(alpha = 0.16f) else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.45f)
    Card(
        modifier = Modifier
            .width(180.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = background),
        border = BorderStroke(
            1.dp,
            if (selected) region.accent else MaterialTheme.colorScheme.outline.copy(alpha = 0.15f)
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(14.dp)
                    .clip(CircleShape)
                    .background(region.accent)
            )
            Text(
                text = region.name,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = "${region.activeVendorCount} mitra aktif",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "Rata-rata kirim ${region.avgEta}",
                style = MaterialTheme.typography.labelLarge,
                color = region.accent
            )
        }
    }
}

@Composable
private fun VendorCard(
    vendor: CateringVendor,
    selected: Boolean,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(28.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (selected) MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.55f) else MaterialTheme.colorScheme.surface
        ),
        border = BorderStroke(
            1.dp,
            if (selected) MaterialTheme.colorScheme.secondary else MaterialTheme.colorScheme.outline.copy(alpha = 0.18f)
        )
    ) {
        Column(modifier = Modifier.padding(18.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = vendor.name,
                        style = MaterialTheme.typography.titleLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = vendor.shortDescription,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Spacer(modifier = Modifier.width(12.dp))
                Surface(
                    shape = RoundedCornerShape(16.dp),
                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)
                ) {
                    Text(
                        text = "${vendor.rating} (${vendor.reviewCount})",
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                        style = MaterialTheme.typography.labelLarge,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
            Spacer(modifier = Modifier.height(12.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                InfoPill(vendor.region)
                InfoPill(vendor.eta)
                InfoPill(vendor.priceRange)
            }
            Spacer(modifier = Modifier.height(12.dp))
            TagCloud(tags = vendor.tags)
        }
    }
}

@Composable
private fun VendorDetailCard(
    vendor: CateringVendor,
    onAddPackage: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(30.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
    ) {
        Column(modifier = Modifier.padding(20.dp)) {
            SectionTitle(
                title = vendor.name,
                subtitle = "${vendor.region} • ${vendor.minOrder} • ${vendor.eta}"
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = vendor.shortDescription,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(14.dp))
            Text(
                text = "Menu unggulan",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(8.dp))
            TagCloud(tags = vendor.featuredMenus)
            Spacer(modifier = Modifier.height(18.dp))
            Text(
                text = "Paket tersedia",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(10.dp))
            vendor.packages.forEachIndexed { index, menuPackage ->
                PackageCard(menuPackage = menuPackage, onAddPackage = onAddPackage)
                if (index != vendor.packages.lastIndex) {
                    Spacer(modifier = Modifier.height(10.dp))
                }
            }
        }
    }
}

@Composable
private fun PackageCard(
    menuPackage: MenuPackage,
    onAddPackage: () -> Unit
) {
    Surface(
        shape = RoundedCornerShape(24.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = menuPackage.title,
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = menuPackage.price,
                        style = MaterialTheme.typography.titleLarge,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
                Button(
                    onClick = onAddPackage,
                    shape = RoundedCornerShape(18.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                ) {
                    Text("Tambah")
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = menuPackage.description,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Minimum pesanan ${menuPackage.minimumOrder}",
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.secondary
            )
        }
    }
}

@Composable
private fun SellerDashboard() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            DashboardHero(
                title = "Dashboard Penjual",
                description = "Kelola performa katering, update paket favorit, dan pantau wilayah pengiriman paling aktif.",
                accent = MaterialTheme.colorScheme.secondary
            )
        }
        item {
            StatsRow(
                stats = listOf(
                    "Pesanan Hari Ini" to "42",
                    "Pendapatan" to "Rp8,4jt",
                    "Repeat Order" to "67%"
                )
            )
        }
        item {
            SectionTitle(
                title = "Paket yang paling sering dipesan",
                subtitle = "Urut berdasarkan konversi minggu ini."
            )
        }
        items(
            listOf(
                "Paket Premium Meeting" to "17 pesanan • Margin tinggi • Rating 4.9",
                "Paket Lunch Fit" to "11 pesanan • Banyak repeat • Cocok untuk kantor",
                "Paket Gathering" to "9 pesanan • Cocok event komunitas"
            )
        ) { item ->
            SimpleInsightCard(title = item.first, description = item.second)
        }
        item {
            SectionTitle(
                title = "Area pengiriman aktif",
                subtitle = "Wilayah yang sedang ramai dan layak diprioritaskan."
            )
        }
        item {
            LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                items(regions) { region ->
                    RegionMapCard(region = region, selected = region.name == "Jakarta Selatan", onClick = {})
                }
            }
        }
        item {
            SectionTitle(
                title = "Aksi cepat penjual",
                subtitle = "Langkah singkat supaya operasional tetap lancar."
            )
        }
        items(
            listOf(
                "Update stok menu buffet untuk hari Jumat",
                "Perluas area kirim ke Jakarta Pusat dan Tangerang",
                "Aktifkan promo langganan mingguan untuk kantor"
            )
        ) { item ->
            ChecklistCard(text = item)
        }
    }
}

@Composable
private fun AdminDashboard() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            DashboardHero(
                title = "Control Center Admin",
                description = "Pantau merchant, buyer, transaksi, dan pemerataan supply katering di tiap wilayah.",
                accent = MaterialTheme.colorScheme.tertiary
            )
        }
        item {
            StatsRow(
                stats = listOf(
                    "Merchant Aktif" to "80",
                    "Order Mingguan" to "1.248",
                    "Wilayah Padat" to "Jaksel"
                )
            )
        }
        item {
            SectionTitle(
                title = "Antrian verifikasi merchant",
                subtitle = "Prioritaskan partner baru agar coverage wilayah makin merata."
            )
        }
        items(
            listOf(
                "Dapoer Harmoni - Bandung • Dokumen lengkap • Menunggu approval",
                "Mitra Rasa Kita - Tangerang • Perlu cek foto dapur",
                "Buffet Bahari - Jakarta Barat • Perlu validasi menu halal"
            )
        ) { item ->
            SimpleInsightCard(title = item.substringBefore(" - "), description = item.substringAfter(" - "))
        }
        item {
            SectionTitle(
                title = "Monitoring wilayah",
                subtitle = "Region dengan demand tinggi tapi supply perlu ditambah."
            )
        }
        item {
            FlowRegionMatrix()
        }
        item {
            SectionTitle(
                title = "Aksi admin berikutnya",
                subtitle = "Supaya pengalaman pengguna tetap stabil dan cepat."
            )
        }
        items(
            listOf(
                "Tambah merchant terkurasi di Jakarta Pusat",
                "Audit SLA pengiriman vendor dengan ETA di atas 35 menit",
                "Naikkan exposure katering sehat di Jakarta Barat"
            )
        ) { item ->
            ChecklistCard(text = item)
        }
    }
}

@Composable
private fun DashboardHero(
    title: String,
    description: String,
    accent: Color
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(28.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 8.dp
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    brush = Brush.linearGradient(
                        colors = listOf(
                            accent.copy(alpha = 0.86f),
                            MaterialTheme.colorScheme.primary.copy(alpha = 0.75f)
                        )
                    )
                )
                .padding(22.dp)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.onPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = description,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.92f)
            )
        }
    }
}

@Composable
private fun StatsRow(stats: List<Pair<String, String>>) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        stats.forEach { stat ->
            Card(
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(22.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 6.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = stat.second,
                        style = MaterialTheme.typography.headlineSmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = stat.first,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun SimpleInsightCard(title: String, description: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(24.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(modifier = Modifier.padding(18.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = description,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun FlowRegionMatrix() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(28.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 6.dp)
    ) {
        FlowRow(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            regions.forEach { region ->
                Surface(
                    shape = RoundedCornerShape(20.dp),
                    color = region.accent.copy(alpha = 0.14f)
                ) {
                    Column(
                        modifier = Modifier
                            .width(150.dp)
                            .padding(14.dp)
                    ) {
                        Text(
                            text = region.name,
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = "${region.activeVendorCount} merchant aktif",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "ETA ${region.avgEta}",
                            style = MaterialTheme.typography.labelLarge,
                            color = region.accent
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ChecklistCard(text: String) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(22.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(12.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primary)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = text,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

@Composable
private fun InfoPill(text: String) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f)
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun TagCloud(tags: List<String>) {
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        tags.forEach { tag ->
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.08f)
            ) {
                Text(
                    text = tag,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}

@Composable
private fun SectionTitle(title: String, subtitle: String) {
    Column {
        Text(
            text = title,
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onBackground
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = subtitle,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Preview(showBackground = true, showSystemUi = true)
@Composable
private fun CateringAppPreview() {
    AskiaCateringTheme {
        CateringApp()
    }
}
