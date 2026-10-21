from models.db.models import FacilityDirectory


async def test_facilities_api_exposes_and_filters_verified_capabilities(async_client, db_session):
    db_session.add_all(
        [
            FacilityDirectory(
                id="fac-blood",
                name="Verified FRU",
                facility_level="FRU",
                district="Test district",
                latitude=20.0,
                longitude=77.0,
                services_json='["blood_bank:yes", "delivery_room:yes"]',
                is_active=True,
                last_updated_at=1,
            ),
            FacilityDirectory(
                id="fac-generic",
                name="Generic PHC",
                facility_level="PHC",
                district="Test district",
                latitude=20.1,
                longitude=77.1,
                services_json='["outpatient", "blood_bank:no"]',
                is_active=True,
                last_updated_at=1,
            ),
        ]
    )
    await db_session.commit()

    response = await async_client.get("/api/v1/facilities", params={"capability": "blood_bank"})

    assert response.status_code == 200
    body = response.json()
    assert body["count"] == 1
    assert body["facilities"][0]["id"] == "fac-blood"
    assert body["facilities"][0]["capabilities"] == ["blood_bank", "delivery_room"]

