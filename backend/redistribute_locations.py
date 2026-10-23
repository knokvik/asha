"""Location redistribution script:
Updates existing households, members, encounters, and referrals to match:
- 12 members in Delhi Area (Najafgarh, Mehrauli, Narela, Bawana, Dwarka)
- 6 members in Pune Area (Hadapsar, Akurdi)
- 6 members in Mumbai Area (Dharavi, Kurla, Govandi)
Keeps district_code and block_code within varchar(10).
"""
import asyncio
from sqlalchemy import text
from db.session import AsyncSessionLocal

async def redistribute_locations():
    async with AsyncSessionLocal() as session:
        print("--- Starting location redistribution ---")
        
        # ── 1. DELHI AREA (12 Members) ──
        # Vikram Singh household (3 members: Vikram Singh, Kavita Singh, Baby Aarav)
        await session.execute(text("""
            UPDATE households
            SET village = 'Najafgarh', hamlet = 'Ward 12, Roshanpura, Delhi',
                state_code = 'DL', district_code = 'DL_SW', block_code = 'BLK_DEL01',
                landmark_notes = 'Near Delhi Govt Dispensary, Najafgarh'
            WHERE id = 'hh_singh_01';
        """))
        
        # Ramesh Kumar household (3 members: Ramesh Kumar, Pooja Devi, Sita Devi)
        await session.execute(text("""
            UPDATE households
            SET village = 'Mehrauli', hamlet = 'Ward 4, Ward 2 Purwa, South Delhi',
                state_code = 'DL', district_code = 'DL_S', block_code = 'BLK_DEL01',
                landmark_notes = 'Near Primary Health Centre Mehrauli'
            WHERE id = 'hh_kumar_02';
        """))
        
        # Sunil Yadav household (3 members: Sunil Yadav, Meera Yadav, Priya Yadav)
        await session.execute(text("""
            UPDATE households
            SET village = 'Narela', hamlet = 'Ward 7, Alipur Tola, North Delhi',
                state_code = 'DL', district_code = 'DL_N', block_code = 'BLK_DEL02',
                landmark_notes = 'Opposite Delhi MCD Primary School, Narela'
            WHERE id = 'hh_yadav_04';
        """))
        
        # Ramprasad Verma household (2 members: Ramprasad Verma, Kamlesh Verma)
        await session.execute(text("""
            UPDATE households
            SET village = 'Bawana', hamlet = 'Sector 3 Basti, North West Delhi',
                state_code = 'DL', district_code = 'DL_NW', block_code = 'BLK_DEL02',
                landmark_notes = 'Behind Bawana Community Health Post'
            WHERE id = 'hh_verma_03';
        """))

        # Single member record (Yashraj Zagade - Dwarka Delhi, 1 member) -> 3+3+3+2+1 = 12 members in Delhi!
        await session.execute(text("""
            UPDATE households
            SET village = 'Dwarka', hamlet = 'Sector 14, South West Delhi',
                state_code = 'DL', district_code = 'DL_SW', block_code = 'BLK_DEL01',
                landmark_notes = 'Near Dwarka Metro Station & Dispensary'
            WHERE id = '1c2e1026-4c32-41e4-b8a7-88977e2df708';
        """))

        # Update Delhi member records
        delhi_hh_ids = "('hh_singh_01', 'hh_kumar_02', 'hh_yadav_04', 'hh_verma_03', '1c2e1026-4c32-41e4-b8a7-88977e2df708')"
        await session.execute(text(f"""
            UPDATE members
            SET state_code = 'DL', district_code = 'DL_METRO', block_code = 'BLK_DEL'
            WHERE household_id IN {delhi_hh_ids};
        """))

        # ── 2. PUNE AREA (6 Members) ──
        # Manoj Mishra household (3 members: Manoj Mishra, Anjali Mishra, Arjun Mishra)
        await session.execute(text("""
            UPDATE households
            SET village = 'Hadapsar', hamlet = 'Ward 18, Malwadi Basti, Pune',
                state_code = 'MH', district_code = 'MH_PUN', block_code = 'BLK_PUN01',
                landmark_notes = 'Near Hadapsar UPHC & Saswad Road'
            WHERE id = 'hh_mishra_06';
        """))

        # Suresh Chauhan household (3 members: Suresh Chauhan, Suman Chauhan, Rohit Chauhan) -> 3+3 = 6 members in Pune!
        await session.execute(text("""
            UPDATE households
            SET village = 'Akurdi', hamlet = 'Ward W3, Akurdi Gaon, PCMC Pune',
                state_code = 'MH', district_code = 'MH_PUN', block_code = 'BLK_PUN02',
                landmark_notes = 'Near Vitthal Temple, Akurdi, PCMC Pune'
            WHERE id = 'hh_chauhan_07';
        """))

        pune_hh_ids = "('hh_mishra_06', 'hh_chauhan_07')"
        await session.execute(text(f"""
            UPDATE members
            SET state_code = 'MH', district_code = 'MH_PUN', block_code = 'BLK_PUN'
            WHERE household_id IN {pune_hh_ids};
        """))

        # ── 3. MUMBAI AREA (6 Members) ──
        # Harish Chandra household (2 members: Harish Chandra, Saroj Chandra)
        await session.execute(text("""
            UPDATE households
            SET village = 'Dharavi', hamlet = 'Sector 5, Kumbharwada, Mumbai',
                state_code = 'MH', district_code = 'MH_MUM', block_code = 'BLK_MUM01',
                landmark_notes = 'Near Dharavi Urban Health Centre'
            WHERE id = 'hh_chandra_08';
        """))

        # Jagdish Prasad household (2 members: Jagdish Prasad, Manju Prasad)
        await session.execute(text("""
            UPDATE households
            SET village = 'Kurla', hamlet = 'Ward L, Kasaiwada, Kurla West, Mumbai',
                state_code = 'MH', district_code = 'MH_MUM', block_code = 'BLK_MUM02',
                landmark_notes = 'Opposite Bhabha Hospital Road, Kurla'
            WHERE id = 'hh_prasad_10';
        """))

        # Shanti Devi household (2 members: Shanti Devi, Vinod Kumar) -> 2+2+2 = 6 members in Mumbai!
        await session.execute(text("""
            UPDATE households
            SET village = 'Govandi', hamlet = 'Ward M-East, Shivaji Nagar, Mumbai',
                state_code = 'MH', district_code = 'MH_MUM', block_code = 'BLK_MUM02',
                landmark_notes = 'Near Shatabdi Municipal Hospital, Govandi'
            WHERE id = 'hh_shanti_05';
        """))

        mumbai_hh_ids = "('hh_chandra_08', 'hh_prasad_10', 'hh_shanti_05')"
        await session.execute(text(f"""
            UPDATE members
            SET state_code = 'MH', district_code = 'MH_MUM', block_code = 'BLK_MUM'
            WHERE household_id IN {mumbai_hh_ids};
        """))

        # Update remaining older single records or assign them to Deepak Pandey household:
        # Deepak Pandey (3 members: Deepak, Geeta, Sakshi) -> set to Greater Delhi / NCR or merge
        await session.execute(text("""
            UPDATE households
            SET village = 'Rohini', hamlet = 'Sector 16, North West Delhi',
                state_code = 'DL', district_code = 'DL_NW', block_code = 'BLK_DEL02',
                landmark_notes = 'Near Ambedkar Hospital, Rohini'
            WHERE id = 'hh_pandey_09';
        """))
        await session.execute(text("""
            UPDATE members
            SET state_code = 'DL', district_code = 'DL_METRO', block_code = 'BLK_DEL'
            WHERE household_id = 'hh_pandey_09';
        """))

        # Update single user records
        await session.execute(text("""
            UPDATE households 
            SET village = 'Kothrud', hamlet = 'Dahanukar Colony, Pune', state_code = 'MH', district_code = 'MH_PUN', block_code = 'BLK_PUN01'
            WHERE id = '285511d5-0e49-454c-b086-12f6afc2f199';
        """))
        await session.execute(text("""
            UPDATE households 
            SET village = 'Shivajinagar', hamlet = 'Wakdewadi, Pune', state_code = 'MH', district_code = 'MH_PUN', block_code = 'BLK_PUN01'
            WHERE id = '5fbf80e6-f39b-4814-b280-c51ab49b9744';
        """))
        await session.execute(text("""
            UPDATE households 
            SET village = 'Andheri East', hamlet = 'Marol Naka, Mumbai', state_code = 'MH', district_code = 'MH_MUM', block_code = 'BLK_MUM01'
            WHERE id = '923f3270-ac66-4cd1-ac77-3c4e4078faf2';
        """))

        # Update referral destinations to respective regional tertiary centers
        # Delhi referrals -> AIIMS Central
        await session.execute(text("""
            UPDATE referral_records
            SET destination_facility_id = 'bb-del-1', destination_level = 'AIIMS New Delhi'
            WHERE member_id IN ('mem_pooja_01', 'mem_ramprasad_03');
        """))
        
        # Mumbai referrals -> KEM Hospital Mumbai
        await session.execute(text("""
            UPDATE referral_records
            SET destination_facility_id = 'bb-mum-1', destination_level = 'KEM Hospital Mumbai'
            WHERE member_id IN ('mem_harish_08', 'mem_jagdish_10', 'mem_shanti_05');
        """))

        # Pune referrals -> Red Cross Pune / YCM Hospital
        await session.execute(text("""
            UPDATE referral_records
            SET destination_facility_id = 'bb-pun-1', destination_level = 'YCM Hospital Pune'
            WHERE member_id IN ('mem_anjali_06', 'mem_rohit_07');
        """))

        await session.commit()
        print("SUCCESS: Locations redistributed successfully!")

        # Verification breakdown
        res = await session.execute(text("""
            SELECT 
                CASE 
                    WHEN h.village IN ('Najafgarh', 'Mehrauli', 'Narela', 'Bawana', 'Dwarka') THEN 'Delhi Area (Primary 12)'
                    WHEN h.village IN ('Hadapsar', 'Akurdi') THEN 'Pune Area (Primary 6)'
                    WHEN h.village IN ('Dharavi', 'Kurla', 'Govandi') THEN 'Mumbai Area (Primary 6)'
                    ELSE h.village
                END as region_group,
                count(m.id) as total_members,
                count(DISTINCT h.id) as total_households,
                string_agg(DISTINCT h.village, ', ') as villages
            FROM households h
            JOIN members m ON m.household_id = h.id
            GROUP BY 1
            ORDER BY total_members DESC;
        """))
        print("\n--- REGIONAL BREAKDOWN IN DB ---")
        for r in res.fetchall():
            print(dict(r._mapping))

if __name__ == '__main__':
    asyncio.run(redistribute_locations())
